import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../l10n/strings.dart';
import '../../models/settings.dart';
import '../theme.dart';
import '../icons.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _showEntry(
      BuildContext context, AppState app, int index, HistoryEntry entry) {
    final s = S.of(context);
    final c = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
              Text(s.historyDetails, style: T.display(26, color: c.tx)),
              const SizedBox(height: 4),
              Text(entry.workoutName,
                  style: T.body(17, weight: 700, color: c.tx)),
              Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(entry.startedAt)} · ${TimeOfDay.fromDateTime(entry.startedAt).format(context)}',
                  style: T.body(13, color: c.mu)),
              const SizedBox(height: 16),
              _DetailLine(s.time, formatClock(entry.elapsedSeconds)),
              _DetailLine(s.work, formatClock(entry.workSeconds)),
              _DetailLine(s.rest, formatClock(entry.restSeconds)),
              _DetailLine(
                  s.intervals,
                  s.intervalsProgress(
                      entry.intervalsDone, entry.intervalsTotal)),
              const SizedBox(height: 16),
              SecondaryButton(
                label: s.rename,
                onPressed: () async {
                  Navigator.pop(sheet);
                  final name = await showNameSheet(context,
                      title: s.workoutName,
                      initial: entry.workoutName,
                      presets: const []);
                  if (name != null && context.mounted) {
                    app.updateHistoryEntry(
                        index, entry.copyWith(workoutName: name));
                  }
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: s.deleteHistoryEntry,
                color: c.danger,
                onPressed: () async {
                  Navigator.pop(sheet);
                  final ok = await confirmDialog(context,
                      title: s.deleteHistoryEntryQ,
                      message: s.cannotUndo,
                      confirm: s.delete);
                  if (ok && context.mounted) app.deleteHistoryEntry(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _day(BuildContext context, DateTime d, S s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return s.today;
    if (diff == 1) return s.yesterday;
    return MaterialLocalizations.of(context).formatMediumDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    final app = AppScope.of(context);
    final items = app.history;

    final groups = <String, List<HistoryEntry>>{};
    for (final h in items) {
      groups.putIfAbsent(_day(context, h.startedAt, s), () => []).add(h);
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppLayout.pageInset, 16, AppLayout.pageInset, 32),
        children: [
          Row(
            children: [
              Expanded(child: ScreenTitle(s.history)),
              if (items.isNotEmpty)
                IconButton(
                  tooltip: s.more,
                  icon: Icon(AppIcons.more, color: c.tx),
                  onPressed: () async {
                    final action = await showOptionSheet<String>(
                      context,
                      title: s.history,
                      items: [
                        OptionSheetItem('clear', s.clearHistory,
                            destructive: true)
                      ],
                    );
                    if (action != 'clear' || !context.mounted) return;
                    final ok = await confirmDialog(context,
                        title: s.clearHistory,
                        message: s.cannotUndo,
                        confirm: s.delete);
                    if (ok) app.clearHistory();
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Surface(
              padding: const EdgeInsets.all(20),
              child: Text(s.emptyHistory,
                  style: T.body(15, color: c.mu, height: 1.4)),
            ),
          for (final entry in groups.entries) ...[
            SectionLabel(entry.key),
            const SizedBox(height: 10),
            for (final h in entry.value) ...[
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => _showEntry(context, app, items.indexOf(h), h),
                  child: Surface(
                    radius: 18,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: h.completed ? Phase.work : c.dash,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.workoutName,
                                  style: T.body(16, weight: 700, color: c.tx),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '${TimeOfDay.fromDateTime(h.startedAt).format(context)} · ${s.intervals.toLowerCase()} ${s.intervalsProgress(h.intervalsDone, h.intervalsTotal)}',
                                style: T.body(13, color: c.mu),
                              ),
                            ],
                          ),
                        ),
                        Text(formatClock(h.elapsedSeconds),
                            style: T.display(24, color: c.tx)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 36,
      child: Row(children: [
        Expanded(child: Text(label, style: T.body(15, color: c.mu))),
        Text(value, style: T.body(16, weight: 700, color: c.tx)),
      ]),
    );
  }
}
