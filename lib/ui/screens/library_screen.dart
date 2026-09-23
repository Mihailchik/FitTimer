import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/presets.dart';
import '../../l10n/strings.dart';
import '../../models/workout.dart';
import '../theme.dart';
import '../icons.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'editor_screen.dart';
import 'run_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final s = S.of(context);
    final name = await showNameSheet(
      context,
      title: s.workoutName,
      initial: '',
      presets: NamePresets.forWorkout(s),
    );
    if (name == null || !context.mounted) return;
    final w = Workout.create(name: name, blocks: [
      WorkBlock.create(name: NamePresets.forBlock(s)[1], intervals: [
        WorkInterval.create(
            name: NamePresets.forInterval(IntervalType.work, s).first,
            seconds: 40),
        WorkInterval.create(
            name: NamePresets.forInterval(IntervalType.rest, s).first,
            seconds: 20,
            type: IntervalType.rest),
      ]),
    ]);
    AppScope.read(context).saveWorkout(w);
    Navigator.of(context).push(appRoute((_) => EditorScreen(workoutId: w.id)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final app = AppScope.of(context);
    final workouts = app.workouts;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppLayout.pageInset, 16, AppLayout.pageInset, 32),
        children: [
          Row(
            children: [
              Expanded(child: ScreenTitle(s.workouts)),
              RoundIconButton(
                  icon: AppIcons.add,
                  tooltip: s.newWorkout,
                  onPressed: () => _create(context)),
            ],
          ),
          const SizedBox(height: 20),
          const _QuickStartCard(),
          const SizedBox(height: 24),
          SectionLabel(s.myWorkouts),
          const SizedBox(height: 10),
          if (workouts.isEmpty)
            Surface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.emptyWorkouts,
                      style: T.body(15, color: c.mu, height: 1.4)),
                  const SizedBox(height: 14),
                  SecondaryButton(
                      label: s.newWorkout,
                      icon: AppIcons.add,
                      onPressed: () => _create(context)),
                ],
              ),
            )
          else
            for (final w in workouts) ...[
              _WorkoutRow(workout: w),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final app = AppScope.of(context);
    final st = app.settings;
    final total = (st.quickWork + st.quickRest) * st.quickRounds;

    Widget tile(String label, Color color, String value, VoidCallback onTap) =>
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 86,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      textAlign: TextAlign.center,
                      style: T.body(15, weight: 600, color: color)),
                  const SizedBox(height: 4),
                  Text(value,
                      textAlign: TextAlign.center,
                      style: T.display(28, color: c.tx, height: 1.0)),
                ],
              ),
            ),
          ),
        );

    return Surface(
      radius: AppLayout.cardRadius,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel(s.quickStart)),
              Text.rich(TextSpan(children: [
                TextSpan(text: '${s.total} ', style: T.body(13, color: c.mu)),
                TextSpan(
                    text: formatClock(total),
                    style: T.body(13, weight: 700, color: c.tx)),
              ])),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: c.s2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(children: [
              tile(s.work, c.work, formatClock(st.quickWork), () async {
                final v = await showDurationSheet(context,
                    title: s.work, seconds: st.quickWork, accent: c.work);
                if (v != null) {
                  app.updateSettings(app.settings.copyWith(quickWork: v));
                }
              }),
              Container(width: 1, height: 48, color: c.line),
              tile(s.rest, c.rest, formatClock(st.quickRest), () async {
                final v = await showDurationSheet(context,
                    title: s.rest, seconds: st.quickRest, accent: c.rest);
                if (v != null) {
                  app.updateSettings(app.settings.copyWith(quickRest: v));
                }
              }),
              Container(width: 1, height: 48, color: c.line),
              tile(s.rounds, c.mu, '${st.quickRounds}', () async {
                final v = await showCountSheet(context,
                    title: s.rounds, value: st.quickRounds);
                if (v != null) {
                  app.updateSettings(app.settings.copyWith(quickRounds: v));
                }
              }),
            ]),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: s.start,
            onPressed: () => openRun(
              context,
              WorkoutTemplate.simple(s, s.quickWorkoutName,
                  work: st.quickWork,
                  rest: st.quickRest,
                  rounds: st.quickRounds),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.templates, style: T.body(14, weight: 700, color: c.mu)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final template in WorkoutTemplate.all) ...[
                  _TemplateChoice(template: template),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateChoice extends StatelessWidget {
  const _TemplateChoice({required this.template});
  final WorkoutTemplate template;

  void _saveAndEdit(BuildContext context) {
    final w = template.build(S.of(context));
    AppScope.read(context).saveWorkout(w);
    Navigator.of(context).push(appRoute((_) => EditorScreen(workoutId: w.id)));
  }

  void _open(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final w = template.build(s);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      sheetAnimationStyle: AnimationStyle.noAnimation,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppLayout.pageInset, 0, AppLayout.pageInset, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(template.title, style: T.display(28, color: c.tx)),
              const SizedBox(height: 4),
              Text(template.info(s).replaceAll('\n', ' · '),
                  style: T.body(15, color: c.mu)),
              const SizedBox(height: 14),
              PhaseStrip(workout: w, height: 10),
              const SizedBox(height: 20),
              PrimaryButton(
                label: '${s.start} · ${formatClock(w.totalSeconds)}',
                onPressed: () {
                  Navigator.pop(sheet);
                  openRun(context, w);
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: s.saveAndEdit,
                icon: AppIcons.edit,
                onPressed: () {
                  Navigator.pop(sheet);
                  _saveAndEdit(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.s2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child:
              Text(template.title, style: T.body(14, weight: 700, color: c.tx)),
        ),
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    return Material(
      color: c.s1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
          side: BorderSide(color: c.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        onTap: () => Navigator.of(context)
            .push(appRoute((_) => EditorScreen(workoutId: workout.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name,
                        style: T.body(16, weight: 700, color: c.tx),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                            width: 72,
                            child: PhaseStrip(workout: workout, maxBars: 6)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${formatClock(workout.totalSeconds)} · ${s.blocksCount(workout.blocks.length)}',
                            style: T.body(13, color: c.mu),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(s.detailsAndEdit,
                        style: T.body(13, weight: 700, color: c.work)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                icon: AppIcons.play,
                tooltip: '${s.start}: ${workout.name}',
                background: Phase.work,
                foreground: Phase.onWork,
                bordered: false,
                iconSize: 26,
                onPressed:
                    workout.isEmpty ? null : () => openRun(context, workout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
