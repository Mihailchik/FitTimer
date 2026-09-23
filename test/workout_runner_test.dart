import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/engine/timeline.dart';
import 'package:flutter_timer/engine/workout_runner.dart';
import 'package:flutter_timer/models/workout.dart';

class FakeClock {
  DateTime now = DateTime(2026, 1, 1, 12);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

Workout _workout({int work = 40, int rest = 20, int rounds = 3}) => Workout.create(
      name: 'Test',
      blocks: [
        WorkBlock.create(name: 'Round', repeats: rounds, intervals: [
          WorkInterval.create(name: 'Work', seconds: work, type: IntervalType.work),
          WorkInterval.create(name: 'Rest', seconds: rest, type: IntervalType.rest),
        ]),
      ],
    );

void main() {
  group('buildTimeline', () {
    test('expands repeats and adds preparation named after first interval', () {
      final t = buildTimeline(_workout(rounds: 2), prepSeconds: 10);
      expect(t.map((s) => s.type), [
        IntervalType.prep,
        IntervalType.work,
        IntervalType.rest,
        IntervalType.work,
        IntervalType.rest,
      ]);
      expect(t.first.seconds, 10);
      expect(t[3].round, 2);
    });

    test('skips zero-length intervals and prep when nothing to play', () {
      final w = Workout.create(name: 'x', blocks: [
        WorkBlock.create(name: 'b', intervals: [
          WorkInterval.create(name: 'zero', seconds: 0),
        ]),
      ]);
      expect(buildTimeline(w, prepSeconds: 10), isEmpty);
    });
  });

  group('WorkoutRunner', () {
    late FakeClock clock;
    late List<Cue> cues;

    WorkoutRunner make({int prep = 5, int rounds = 3}) {
      clock = FakeClock();
      cues = [];
      return WorkoutRunner(
        segments: buildTimeline(_workout(rounds: rounds), prepSeconds: prep),
        clock: clock.call,
        tickEvery: Duration.zero,
        onCue: cues.add,
      );
    }

    test('display counts down from the clock, not from ticks', () {
      final r = make();
      expect(r.displaySeconds, 5);
      clock.advance(const Duration(milliseconds: 2300));
      expect(r.displaySeconds, 3);
      r.dispose();
    });

    test('moves through segments and fires countdown and start cues once', () {
      final r = make();
      for (var i = 0; i < 60; i++) {
        clock.advance(const Duration(milliseconds: 100));
        r.tick();
      }
      expect(r.index, 1);
      expect(r.current.type, IntervalType.work);
      expect(cues, [
        const Cue(CueKind.countdown, 3),
        const Cue(CueKind.countdown, 2),
        const Cue(CueKind.countdown, 1),
        const Cue(CueKind.workStart),
      ]);
      r.dispose();
    });

    test('halfway cue for long work intervals', () {
      final r = make(prep: 0);
      clock.advance(const Duration(seconds: 20));
      r.tick();
      expect(cues, [const Cue(CueKind.halfway)]);
      r.dispose();
    });

    test('pause freezes time and resume continues exactly', () {
      final r = make();
      clock.advance(const Duration(seconds: 2));
      r.pause();
      clock.advance(const Duration(minutes: 5));
      expect(r.displaySeconds, 3);
      r.resume();
      clock.advance(const Duration(seconds: 1));
      r.tick();
      expect(r.index, 0);
      expect(r.displaySeconds, 2);
      r.dispose();
    });

    test('catching up after background lands on the right interval silently', () {
      final r = make(); // 5 prep + 3 x (40 + 20)
      clock.advance(const Duration(seconds: 5 + 60 + 45));
      r.tick();
      expect(r.index, 4); // round 2 rest
      expect(r.current.round, 2);
      expect(r.displaySeconds, 15);
      expect(cues, isEmpty, reason: 'missed cues must not play late in a burst');
      r.dispose();
    });

    test('finishes at the end and fires finish cue', () {
      final r = make(prep: 0, rounds: 1);
      for (var i = 0; i < 600; i++) {
        clock.advance(const Duration(milliseconds: 100));
        r.tick();
      }
      expect(r.status, RunStatus.finished);
      expect(cues.last, const Cue(CueKind.finish));
      expect(r.totalRemaining, Duration.zero);
      r.dispose();
    });

    test('skip forward and back', () {
      final r = make();
      r.skipForward();
      expect(r.index, 1);
      expect(cues, [const Cue(CueKind.workStart)]);
      clock.advance(const Duration(seconds: 1));
      r.skipBack(); // just started -> previous
      expect(r.index, 0);
      clock.advance(const Duration(seconds: 3));
      r.skipBack(); // well into it -> restart same
      expect(r.index, 0);
      expect(r.displaySeconds, 5);
      r.dispose();
    });

    test('stop keeps partial stats', () {
      final r = make(prep: 0);
      clock.advance(const Duration(seconds: 50));
      r.tick();
      r.stop();
      expect(r.status, RunStatus.finished);
      expect(r.finishedEarly, isTrue);
      expect(r.secondsOfType(IntervalType.work), const Duration(seconds: 40));
      expect(r.secondsOfType(IntervalType.rest), const Duration(seconds: 10));
      expect(r.intervalsDone, 1);
      r.dispose();
    });
  });
}
