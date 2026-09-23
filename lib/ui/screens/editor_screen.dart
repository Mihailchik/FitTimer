import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../data/presets.dart';
import '../../l10n/strings.dart';
import '../../models/workout.dart';
import '../theme.dart';
import '../icons.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'run_screen.dart';

/// Edits a saved workout. Every change is saved immediately.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, required this.workoutId});
  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final w = app.workoutById(workoutId);
    if (w == null) return const Scaffold();
    return _Editor(workout: w);
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.workout});
  final Workout workout;

  void _save(BuildContext context, Workout w) =>
      AppScope.read(context).saveWorkout(w);

  void _setBlocks(BuildContext context, List<WorkBlock> blocks) =>
      _save(context, workout.copyWith(blocks: blocks));

  void _setBlock(BuildContext context, int i, WorkBlock b) {
    final blocks = [...workout.blocks]..[i] = b;
    _setBlocks(context, blocks);
  }

  Future<void> _rename(BuildContext context) async {
    final s = S.of(context);
    final name = await showNameSheet(context,
        title: s.workoutName,
        initial: workout.name,
        presets: NamePresets.forWorkout(s));
    if (name != null && context.mounted) {
      _save(context, workout.copyWith(name: name));
    }
  }

  Future<void> _addBlock(BuildContext context) async {
    final s = S.of(context);
    final presets = NamePresets.forBlock(s);
    final used = workout.blocks.map((b) => b.name).toSet();
    final suggested = presets.firstWhere((p) => !used.contains(p),
        orElse: () => '${s.block} ${workout.blocks.length + 1}');
    final name = await showNameSheet(context,
        title: s.blockName, initial: suggested, presets: presets);
    if (name == null || !context.mounted) return;
    _setBlocks(context, [
      ...workout.blocks,
      WorkBlock.create(name: name, intervals: [
        WorkInterval.create(
            name: NamePresets.forInterval(IntervalType.work, s).first,
            seconds: 40),
        WorkInterval.create(
            name: NamePresets.forInterval(IntervalType.rest, s).first,
            seconds: 20,
            type: IntervalType.rest),
      ]),
    ]);
  }

  Future<void> _menu(BuildContext context, String action) async {
    final s = S.of(context);
    final app = AppScope.read(context);
    switch (action) {
      case 'rename':
        await _rename(context);
      case 'duplicate':
        final copy = workout.duplicate(s.copyOf(workout.name));
        app.saveWorkout(copy);
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
              appRoute((_) => EditorScreen(workoutId: copy.id)));
        }
      case 'delete':
        final ok = await confirmDialog(context,
            title: s.deleteWorkoutQ, message: s.cannotUndo, confirm: s.delete);
        if (ok && context.mounted) {
          Navigator.of(context).pop();
          app.deleteWorkout(workout.id);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(AppIcons.back, size: 32, color: c.tx),
                    tooltip: s.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _rename(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(workout.name,
                                style: T.display(22, color: c.tx, height: 1.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '${formatClock(workout.totalSeconds)} · ${s.blocksCount(workout.blocks.length)} · ${s.intervalsCount(workout.intervalCount)}',
                              style: T.body(13, color: c.mu),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: s.more,
                    icon: Icon(AppIcons.more, color: c.tx),
                    onPressed: () async {
                      final action = await showOptionSheet<String>(
                        context,
                        title: workout.name,
                        items: [
                          OptionSheetItem('rename', s.rename),
                          OptionSheetItem('duplicate', s.duplicate),
                          OptionSheetItem('delete', s.deleteWorkout,
                              destructive: true),
                        ],
                      );
                      if (action != null && context.mounted) {
                        _menu(context, action);
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppLayout.pageInset, 4, AppLayout.pageInset, 10),
              child: PhaseStrip(workout: workout, height: 8, maxBars: 24),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppLayout.pageInset, 4, AppLayout.pageInset, 24),
                children: [
                  if (workout.blocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(s.emptyWorkout,
                          textAlign: TextAlign.center,
                          style: T.body(15, color: c.mu)),
                    ),
                  for (var i = 0; i < workout.blocks.length; i++) ...[
                    _BlockCard(
                      key: ValueKey(workout.blocks[i].id),
                      block: workout.blocks[i],
                      index: i,
                      count: workout.blocks.length,
                      onChanged: (b) => _setBlock(context, i, b),
                      onAction: (a) {
                        final blocks = [...workout.blocks];
                        switch (a) {
                          case 'duplicate':
                            blocks.insert(i + 1, blocks[i].duplicate());
                          case 'up':
                            if (i > 0) blocks.insert(i - 1, blocks.removeAt(i));
                          case 'down':
                            if (i < blocks.length - 1) {
                              blocks.insert(i + 1, blocks.removeAt(i));
                            }
                          case 'delete':
                            blocks.removeAt(i);
                        }
                        _setBlocks(context, blocks);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  _DashedButton(
                      label: s.addBlock, onTap: () => _addBlock(context)),
                  const SizedBox(height: 24),
                  SecondaryButton(
                    label: s.deleteWorkout,
                    color: c.danger,
                    onPressed: () => _menu(context, 'delete'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppLayout.pageInset, 12, AppLayout.pageInset, 12),
              decoration: BoxDecoration(
                  color: c.bg, border: Border(top: BorderSide(color: c.line))),
              child: PrimaryButton(
                label: '${s.start} · ${formatClock(workout.totalSeconds)}',
                onPressed:
                    workout.isEmpty ? null : () => openRun(context, workout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    super.key,
    required this.block,
    required this.index,
    required this.count,
    required this.onChanged,
    required this.onAction,
  });

  final WorkBlock block;
  final int index;
  final int count;
  final ValueChanged<WorkBlock> onChanged;
  final ValueChanged<String> onAction;

  Future<void> _rename(BuildContext context) async {
    final s = S.of(context);
    final name = await showNameSheet(context,
        title: s.blockName,
        initial: block.name,
        presets: NamePresets.forBlock(s));
    if (name != null) onChanged(block.copyWith(name: name));
  }

  Future<void> _addInterval(BuildContext context) async {
    final lastType =
        block.intervals.isEmpty ? IntervalType.rest : block.intervals.last.type;
    final type =
        lastType == IntervalType.work ? IntervalType.rest : IntervalType.work;
    final r = await showIntervalSheet(context, type: type);
    if (r != null && r.action == IntervalAction.save) {
      onChanged(block.copyWith(intervals: [...block.intervals, r.interval]));
    }
  }

  Future<void> _editInterval(BuildContext context, int i) async {
    final r = await showIntervalSheet(context, initial: block.intervals[i]);
    if (r == null) return;
    final list = [...block.intervals];
    switch (r.action) {
      case IntervalAction.save:
        list[i] = r.interval;
      case IntervalAction.duplicate:
        list[i] = r.interval;
        list.insert(i + 1, r.interval.withNewId());
      case IntervalAction.delete:
        list.removeAt(i);
    }
    onChanged(block.copyWith(intervals: list));
  }

  void _setRepeats(int v) => onChanged(block.copyWith(repeats: v.clamp(1, 99)));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    return Surface(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _rename(context),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
                    child: Text(block.name,
                        style: T.body(16, weight: 700, color: c.tx),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    _StepButton(
                        icon: AppIcons.minus,
                        tooltip: s.fewerRepeats,
                        onTap: block.repeats > 1
                            ? () => _setRepeats(block.repeats - 1)
                            : null),
                    InkWell(
                      onTap: () async {
                        final v = await showCountSheet(context,
                            title: s.rounds, value: block.repeats);
                        if (v != null) _setRepeats(v);
                      },
                      child: SizedBox(
                        width: 40,
                        child: Text('×${block.repeats}',
                            textAlign: TextAlign.center,
                            style: T.display(19, color: c.tx)),
                      ),
                    ),
                    _StepButton(
                        icon: AppIcons.add,
                        tooltip: s.moreRepeats,
                        onTap: () => _setRepeats(block.repeats + 1)),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.more,
                icon: Icon(AppIcons.moreVertical, color: c.mu),
                onPressed: () async {
                  final action = await showOptionSheet<String>(
                    context,
                    title: block.name,
                    items: [
                      OptionSheetItem('rename', s.rename),
                      OptionSheetItem('duplicate', s.duplicate),
                      if (index > 0) OptionSheetItem('up', s.moveUp),
                      if (index < count - 1)
                        OptionSheetItem('down', s.moveDown),
                      OptionSheetItem('delete', s.delete, destructive: true),
                    ],
                  );
                  if (action == null || !context.mounted) return;
                  if (action == 'rename') {
                    _rename(context);
                  } else {
                    onAction(action);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (block.intervals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Text(s.emptyBlock, style: T.body(14, color: c.mu)),
            ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: block.intervals.length,
            proxyDecorator: (child, _, __) => Material(
                color: Colors.transparent,
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: child),
            onReorderItem: (from, to) {
              final list = [...block.intervals];
              list.insert(to, list.removeAt(from));
              HapticFeedback.selectionClick();
              onChanged(block.copyWith(intervals: list));
            },
            itemBuilder: (context, i) {
              final it = block.intervals[i];
              return Padding(
                key: ValueKey(it.id),
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: c.row,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _editInterval(context, i),
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 14),
                              child:
                                  Icon(AppIcons.drag, size: 20, color: c.grip),
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 28,
                            decoration: BoxDecoration(
                                color: Phase.fill(it.type),
                                borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(it.name,
                                style: T.body(15, weight: 600, color: c.tx),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 64),
                            height: 36,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: c.chip,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(formatClock(it.seconds),
                                style: T.display(19, color: c.tx)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addInterval(context),
              icon: Icon(AppIcons.add, color: c.work),
              label: Text(s.addInterval,
                  style: T.body(14, weight: 700, color: c.work)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      icon: Icon(icon, size: 20, color: onTap == null ? c.faint : c.tx),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
      padding: EdgeInsets.zero,
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: AppLayout.actionHeight,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.dash, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.cardRadius)),
        ),
        child: Text('+ $label', style: T.body(16, weight: 600, color: c.mu)),
      ),
    );
  }
}
