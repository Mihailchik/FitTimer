import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/workout.dart';
import 'timeline.dart';

enum RunStatus { running, paused, finished }

enum CueKind { countdown, workStart, restStart, halfway, finish }

class Cue {
  final CueKind kind;
  final int value; // seconds left for countdown cues

  const Cue(this.kind, [this.value = 0]);

  @override
  bool operator ==(Object other) => other is Cue && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => 'Cue($kind, $value)';
}

typedef Clock = DateTime Function();

/// Plays a timeline against the wall clock.
///
/// Time is never counted in ticks: the current position is always derived
/// from when the segment started, so the timer stays exact after lag, a pause,
/// or the app being in the background. [tick] only refreshes the state and
/// fires cues; it can be called as often or as rarely as convenient.
class WorkoutRunner extends ChangeNotifier {
  WorkoutRunner({
    required this.segments,
    this.halfwayCue = true,
    this.onCue,
    Clock? clock,
    Duration tickEvery = const Duration(milliseconds: 100),
  }) : _clock = clock ?? DateTime.now {
    assert(segments.isNotEmpty);
    final now = _clock();
    startedAt = now;
    _segmentStart = now;
    _lastProcessed = now;
    if (tickEvery > Duration.zero) {
      _ticker = Timer.periodic(tickEvery, (_) => tick());
    }
  }

  /// Cues older than this when finally processed (for example after the app
  /// comes back from the background) are dropped instead of played late.
  static const staleCueLimit = Duration(milliseconds: 1500);

  final List<Segment> segments;
  final bool halfwayCue;
  void Function(Cue cue)? onCue;

  final Clock _clock;
  Timer? _ticker;

  late final DateTime startedAt;
  RunStatus _status = RunStatus.running;
  int _index = 0;
  late DateTime _segmentStart;
  Duration _pausedElapsed = Duration.zero;
  late DateTime _lastProcessed;
  DateTime? _finishedAt;

  RunStatus get status => _status;
  int get index => _index;
  Segment get current => segments[_index.clamp(0, segments.length - 1)];
  Segment? get next => _index + 1 < segments.length ? segments[_index + 1] : null;
  bool get isFirst => _index == 0;

  Duration get elapsedInSegment {
    if (_status == RunStatus.finished) return _stoppedElapsed ?? current.duration;
    final raw = _status == RunStatus.paused ? _pausedElapsed : _clock().difference(_segmentStart);
    if (raw < Duration.zero) return Duration.zero;
    return raw > current.duration ? current.duration : raw;
  }

  Duration get remainingInSegment => current.duration - elapsedInSegment;

  /// Whole seconds to show on the big display (rounded up, like a real timer).
  int get displaySeconds {
    final ms = remainingInSegment.inMilliseconds;
    return ms <= 0 ? 0 : (ms + 999) ~/ 1000;
  }

  /// 0..1 progress of the current segment.
  double get segmentProgress {
    final total = current.duration.inMilliseconds;
    return total == 0 ? 1 : elapsedInSegment.inMilliseconds / total;
  }

  Duration get totalDuration =>
      segments.fold(Duration.zero, (sum, s) => sum + s.duration);

  Duration get totalElapsed {
    var done = Duration.zero;
    for (var i = 0; i < _index && i < segments.length; i++) {
      done += segments[i].duration;
    }
    return done + elapsedInSegment;
  }

  Duration get totalRemaining => totalDuration - totalElapsed;

  /// Real time since start, pauses included.
  Duration get wallElapsed => (_finishedAt ?? _clock()).difference(startedAt);

  int get intervalsDone {
    final countable = segments.where((s) => s.type != IntervalType.prep).length;
    final passed = segments.take(_index).where((s) => s.type != IntervalType.prep).length;
    return _status == RunStatus.finished && !_early ? countable : passed;
  }

  int get intervalsTotal => segments.where((s) => s.type != IntervalType.prep).length;

  Duration secondsOfType(IntervalType type) {
    var sum = Duration.zero;
    for (var i = 0; i < segments.length && i <= _index; i++) {
      if (segments[i].type != type) continue;
      sum += i < _index ? segments[i].duration : elapsedInSegment;
    }
    return sum;
  }

  void pause() {
    if (_status != RunStatus.running) return;
    tick();
    if (_status != RunStatus.running) return;
    _pausedElapsed = _clock().difference(_segmentStart);
    _status = RunStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != RunStatus.paused) return;
    final now = _clock();
    _segmentStart = now.subtract(_pausedElapsed);
    _lastProcessed = now;
    _status = RunStatus.running;
    notifyListeners();
  }

  void togglePause() => _status == RunStatus.running ? pause() : resume();

  /// Starts the current interval again from its full length.
  void restartSegment() {
    if (_status == RunStatus.finished) return;
    _jumpTo(_index);
  }

  void skipForward() {
    if (_status == RunStatus.finished) return;
    if (_index + 1 >= segments.length) {
      _finish(fireCue: false);
      notifyListeners();
      return;
    }
    _jumpTo(_index + 1);
    _emitStartCue(_index);
  }

  /// Goes to the start of the current interval, or to the previous one when
  /// the current interval has only just begun.
  void skipBack() {
    if (_status == RunStatus.finished) return;
    if (elapsedInSegment > const Duration(seconds: 2) || _index == 0) {
      _jumpTo(_index);
    } else {
      _jumpTo(_index - 1);
    }
  }

  /// Ends the workout early.
  void stop() {
    if (_status == RunStatus.finished) return;
    tick();
    if (_status == RunStatus.paused) {
      _segmentStart = _clock().subtract(_pausedElapsed);
    }
    _stoppedElapsed = elapsedInSegment;
    _finish(fireCue: false, early: true);
    notifyListeners();
  }

  Duration? _stoppedElapsed;
  bool _early = false;
  bool get finishedEarly => _early;

  void _jumpTo(int i) {
    final now = _clock();
    _index = i;
    _segmentStart = now;
    _pausedElapsed = Duration.zero;
    _lastProcessed = now;
    notifyListeners();
  }

  void _finish({required bool fireCue, bool early = false}) {
    _status = RunStatus.finished;
    _early = early;
    _finishedAt = _clock();
    _ticker?.cancel();
    if (fireCue) onCue?.call(const Cue(CueKind.finish));
  }

  List<(Duration, Cue)> _cuesFor(int i) {
    final seg = segments[i];
    final len = seg.duration;
    final cues = <(Duration, Cue)>[];
    if (i > 0) {
      final start = _startCue(seg.type);
      if (start != null) cues.add((Duration.zero, start));
    }
    if (halfwayCue && seg.type == IntervalType.work && seg.seconds > 30) {
      cues.add((len - Duration(seconds: seg.seconds ~/ 2), const Cue(CueKind.halfway)));
    }
    if (seg.seconds >= 5) {
      for (final n in const [3, 2, 1]) {
        cues.add((len - Duration(seconds: n), Cue(CueKind.countdown, n)));
      }
    }
    return cues;
  }

  Cue? _startCue(IntervalType type) => switch (type) {
        IntervalType.work => const Cue(CueKind.workStart),
        IntervalType.rest => const Cue(CueKind.restStart),
        IntervalType.prep => null,
      };

  void _emitStartCue(int i) {
    final cue = _startCue(segments[i].type);
    if (cue != null) onCue?.call(cue);
  }

  /// Advances through any segments whose time is up and fires due cues.
  void tick() {
    if (_status != RunStatus.running) return;
    final now = _clock();
    final due = <(DateTime, Cue)>[];
    DateTime? reachedEndAt;

    while (true) {
      final start = _segmentStart;
      final end = start.add(current.duration);
      for (final (offset, cue) in _cuesFor(_index)) {
        final at = start.add(offset);
        if (at.isAfter(_lastProcessed) && !at.isAfter(now)) due.add((at, cue));
      }
      if (now.isBefore(end)) break;
      if (_index + 1 >= segments.length) {
        reachedEndAt = end;
        break;
      }
      _index++;
      _segmentStart = end;
    }

    for (final (at, cue) in due) {
      if (now.difference(at) <= staleCueLimit) onCue?.call(cue);
    }
    _lastProcessed = now;

    if (reachedEndAt != null) {
      _finish(fireCue: now.difference(reachedEndAt) <= staleCueLimit);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
