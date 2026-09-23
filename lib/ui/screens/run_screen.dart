import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/app_state.dart';
import '../../engine/background_cues.dart';
import '../../engine/cue_player.dart';
import '../../engine/timeline.dart';
import '../../engine/workout_runner.dart';
import '../../l10n/strings.dart';
import '../../models/settings.dart';
import '../../models/workout.dart';
import '../theme.dart';
import '../icons.dart';
import '../widgets/common.dart';
import 'finish_screen.dart';

Future<void> openRun(BuildContext context, Workout workout) async {
  if (workout.isEmpty) return;
  final app = AppScope.read(context);
  // The notification prompt is shown once, before the first workout starts:
  // it cannot appear from the background, and over a running countdown it
  // would steal the first seconds.
  if (app.settings.backgroundCues && !app.settings.notificationsAsked) {
    await BackgroundCues.instance.requestPermission();
    app.updateSettings(app.settings.copyWith(notificationsAsked: true));
    if (!context.mounted) return;
  }
  Navigator.of(context, rootNavigator: true).push(
    appRoute((_) => RunScreen(workout: workout)),
  );
}

class RunScreen extends StatefulWidget {
  const RunScreen({super.key, required this.workout});
  final Workout workout;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with WidgetsBindingObserver {
  late final WorkoutRunner _runner;
  late final CuePlayer _cues;
  late AppSettings _settings;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _settings = app.settings;
    final firstName = widget.workout.blocks
        .expand((b) => b.intervals)
        .firstWhere((i) => i.seconds > 0,
            orElse: () => widget.workout.blocks.first.intervals.first)
        .name;
    _cues = CuePlayer(
        sound: _settings.sound,
        haptics: _settings.haptics,
        duckMusic: _settings.duckMusic);
    _runner = WorkoutRunner(
      segments: buildTimeline(widget.workout,
          prepSeconds: _settings.prepSeconds, prepName: firstName),
      halfwayCue: _settings.halfwayCue,
      onCue: _cues.play,
    );
    _runner.addListener(_onRunner);
    _cues.init().then((_) {
      if (mounted &&
          _runner.current.type == IntervalType.work &&
          _runner.isFirst) {
        _cues.play(const Cue(CueKind.workStart));
      }
    });
    WidgetsBinding.instance.addObserver(this);
    if (_settings.keepAwake) WakelockPlus.enable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BackgroundCues.instance.cancel();
      _runner.tick();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_settings.backgroundCues && _runner.status == RunStatus.running) {
        BackgroundCues.instance.schedule(
          _runner.upcomingChanges(limit: BackgroundCues.maxPending),
          s: S.of(context),
          sound: _cues.sound,
        );
      }
    }
  }

  void _onRunner() {
    if (_runner.status == RunStatus.finished && !_leaving) {
      _leaving = true;
      _finish();
    }
  }

  Future<void> _finish() async {
    final summary = RunSummary(
      workout: widget.workout,
      elapsed: _runner.totalElapsed,
      work: _runner.secondsOfType(IntervalType.work),
      rest: _runner.secondsOfType(IntervalType.rest),
      intervalsDone: _runner.intervalsDone,
      intervalsTotal: _runner.intervalsTotal,
      early: _runner.finishedEarly,
    );
    AppScope.read(context).addHistory(HistoryEntry(
      workoutName: widget.workout.name,
      startedAt: _runner.startedAt,
      elapsedSeconds: summary.elapsed.inSeconds,
      workSeconds: summary.work.inSeconds,
      restSeconds: summary.rest.inSeconds,
      intervalsDone: summary.intervalsDone,
      intervalsTotal: summary.intervalsTotal,
      completed: !summary.early,
    ));
    // Let the finish chime ring before the screen changes.
    await Future.delayed(Duration(milliseconds: summary.early ? 0 : 700));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      appRoute((_) => FinishScreen(summary: summary)),
    );
  }

  void _toggleSound() {
    final app = AppScope.read(context);
    final next = !_cues.sound;
    _cues.sound = next;
    _settings = _settings.copyWith(sound: next);
    app.updateSettings(app.settings.copyWith(sound: next));
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runner.removeListener(_onRunner);
    _runner.dispose();
    _cues.dispose();
    BackgroundCues.instance.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _runner.pause();
      },
      child: ListenableBuilder(
        listenable: _runner,
        builder: (context, _) {
          final paused = _runner.status == RunStatus.paused;
          final seg = _runner.current;
          final dark = Theme.of(context).brightness == Brightness.dark;
          final bg = dark ? Phase.darkFill(seg.type) : Phase.fill(seg.type);
          final fg = dark ? AppColors.of(context).tx : Phase.on(seg.type);
          final accent = dark ? Phase.fill(seg.type) : fg;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: fg.computeLuminance() < 0.5
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              color: bg,
              child: Material(
                type: MaterialType.transparency,
                child: _RunBody(
                    runner: _runner,
                    bg: bg,
                    fg: fg,
                    accent: accent,
                    paused: paused,
                    soundOn: _cues.sound,
                    onSound: _toggleSound),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RunBody extends StatelessWidget {
  const _RunBody(
      {required this.runner,
      required this.bg,
      required this.fg,
      required this.accent,
      required this.paused,
      required this.soundOn,
      required this.onSound});

  final WorkoutRunner runner;
  final Color bg;
  final Color fg;
  final Color accent;
  final bool paused;
  final bool soundOn;
  final VoidCallback onSound;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final seg = runner.current;
    final next = runner.next;
    final chip = fg.withValues(alpha: 0.12);
    final track = fg.withValues(alpha: 0.18);
    final secs = runner.displaySeconds;
    final digits = secs >= 60 ? formatClock(secs) : '$secs';
    final label = switch (seg.type) {
      IntervalType.work => s.work,
      IntervalType.rest => s.rest,
      IntervalType.prep => s.getReady,
    };
    final name =
        seg.type == IntervalType.prep ? s.nowDoing(seg.name) : seg.name;
    final totalProgress = runner.totalDuration.inMilliseconds == 0
        ? 0.0
        : runner.totalElapsed.inMilliseconds /
            runner.totalDuration.inMilliseconds;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                RoundIconButton(
                  icon: paused ? AppIcons.play : AppIcons.pause,
                  tooltip: paused ? s.resume : s.pauseActions,
                  onPressed: paused ? runner.resume : runner.pause,
                  background: chip,
                  foreground: fg,
                  bordered: false,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(paused ? s.paused : seg.blockName,
                          style: T.body(14,
                              weight: 500, color: fg.withValues(alpha: 0.75)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (seg.rounds > 1)
                        Text(s.roundOf(seg.round, seg.rounds),
                            style: T.body(17, weight: 600, color: fg)),
                    ],
                  ),
                ),
                RoundIconButton(
                  icon: soundOn ? AppIcons.soundOn : AppIcons.soundOff,
                  tooltip: soundOn ? s.turnSoundOff : s.turnSoundOn,
                  onPressed: onSound,
                  background: chip,
                  foreground: fg,
                  bordered: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: runner.togglePause,
              child: LayoutBuilder(
                builder: (context, box) {
                  final ring = min(box.maxWidth - 56, box.maxHeight - 220)
                      .clamp(160.0, 340.0);
                  final center = box.maxHeight / 2;
                  return SizedBox.expand(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: center + ring / 2 + 14,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (name.toLowerCase() != label.toLowerCase())
                                Text(label,
                                    style: T.body(17,
                                        weight: 600,
                                        color: fg.withValues(alpha: 0.7))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: T.display(36, color: fg, height: 1.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: ring,
                          height: ring,
                          child: CustomPaint(
                            painter: _RingPainter(
                                progress: runner.segmentProgress,
                                color: accent,
                                track: track),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(ring * 0.12),
                                child: FittedBox(
                                  child: Text(digits,
                                      style: T.display(170,
                                          color: fg, height: 1, spacing: -2)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: center + ring / 2 + 16,
                          child: Center(
                            child: SizedBox(
                              width: min(box.maxWidth - 24, 300),
                              child: Container(
                                height: 48,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                    color: chip,
                                    borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    Text(s.upNext,
                                        style: T.body(13,
                                            weight: 700,
                                            color: fg.withValues(alpha: 0.7))),
                                    const SizedBox(width: 10),
                                    if (next != null) ...[
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Phase.fill(next.type),
                                          shape: BoxShape.circle,
                                          border:
                                              Border.all(color: fg, width: 1.5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(next?.name ?? s.finishLine,
                                          style: T.body(15,
                                              weight: 700, color: fg),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (next != null) ...[
                                      const SizedBox(width: 8),
                                      Text(formatClock(next.seconds),
                                          style: T.display(18, color: fg)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: totalProgress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: track,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                        '${s.elapsed} ${formatClock(runner.totalElapsed.inSeconds)}',
                        style: T.body(13,
                            weight: 700, color: fg.withValues(alpha: 0.75))),
                    const Spacer(),
                    Text(
                        '${s.remaining} ${formatClock((runner.totalRemaining.inMilliseconds / 1000).ceil())}',
                        style: T.body(13, weight: 700, color: fg)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: Center(
                child: paused
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppLayout.pageInset),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PrimaryButton(
                              label: s.resume,
                              icon: null,
                              color: fg,
                              foreground: bg,
                              onPressed: runner.resume,
                            ),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                  child: SecondaryButton(
                                label: s.restartInterval,
                                onPressed: () {
                                  runner.restartSegment();
                                  runner.resume();
                                },
                              )),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: SecondaryButton(
                                label: s.endWorkout,
                                color: AppColors.of(context).danger,
                                onPressed: runner.stop,
                              )),
                            ]),
                          ],
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RoundIconButton(
                            icon: AppIcons.skipBack,
                            tooltip: s.previous,
                            onPressed: runner.skipBack,
                            size: 64,
                            iconSize: 30,
                            background: chip,
                            foreground: fg,
                            bordered: false,
                          ),
                          const SizedBox(width: 28),
                          RoundIconButton(
                            icon: AppIcons.pause,
                            tooltip: s.pause,
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              runner.pause();
                            },
                            size: 96,
                            iconSize: 44,
                            background: fg,
                            foreground: bg,
                            bordered: false,
                          ),
                          const SizedBox(width: 28),
                          RoundIconButton(
                            icon: AppIcons.skipForward,
                            tooltip: s.nextInterval,
                            onPressed: runner.skipForward,
                            size: 64,
                            iconSize: 30,
                            background: chip,
                            foreground: fg,
                            bordered: false,
                          ),
                        ],
                      )),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.progress, required this.color, required this.track});
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(r, 0, 2 * pi, false, base);
    final left = (1 - progress).clamp(0.0, 1.0);
    if (left <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(r, -pi / 2, 2 * pi * left, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
