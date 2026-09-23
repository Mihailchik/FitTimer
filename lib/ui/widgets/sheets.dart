import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../data/presets.dart';
import '../../l10n/strings.dart';
import '../../models/workout.dart';
import '../theme.dart';
import '../icons.dart';
import 'common.dart';

enum IntervalAction { save, duplicate, delete }

class IntervalSheetResult {
  final IntervalAction action;
  final WorkInterval interval;
  const IntervalSheetResult(this.action, this.interval);
}

class OptionSheetItem<V> {
  const OptionSheetItem(this.value, this.label, {this.destructive = false});

  final V value;
  final String label;
  final bool destructive;
}

/// A consistent choice/action surface instead of platform popup menus.
Future<V?> showOptionSheet<V>(
  BuildContext context, {
  required String title,
  required List<OptionSheetItem<V>> items,
  V? selected,
}) {
  return showModalBottomSheet<V>(
    context: context,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final c = AppColors.of(sheetContext);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: T.display(24, color: c.tx)),
            const SizedBox(height: 16),
            Surface(
              radius: 18,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: c.line),
                      Semantics(
                        button: true,
                        selected: items[i].value == selected,
                        label: items[i].label,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(sheetContext).pop(items[i].value);
                          },
                          child: SizedBox(
                            height: 58,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      items[i].label,
                                      style: T.body(16, weight: 600,
                                          color: items[i].destructive ? c.danger : c.tx),
                                    ),
                                  ),
                                  if (items[i].value == selected)
                                    Icon(AppIcons.check,
                                        size: 20, color: c.navActive),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<R?> _showSheet<R>(BuildContext context, Widget child) {
  return showModalBottomSheet<R>(
    context: context,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: child,
      ),
    ),
  );
}

/// Create or edit one interval: name (with ready-made names), type and time.
Future<IntervalSheetResult?> showIntervalSheet(
  BuildContext context, {
  WorkInterval? initial,
  IntervalType type = IntervalType.work,
}) {
  final s = S.of(context);
  final start = initial ??
      WorkInterval.create(
        name: NamePresets.forInterval(type, s).first,
        seconds: type == IntervalType.rest ? 20 : 40,
        type: type,
      );
  return _showSheet(context, _IntervalSheet(initial: start, isNew: initial == null));
}

class _IntervalSheet extends StatefulWidget {
  const _IntervalSheet({required this.initial, required this.isNew});
  final WorkInterval initial;
  final bool isNew;

  @override
  State<_IntervalSheet> createState() => _IntervalSheetState();
}

class _IntervalSheetState extends State<_IntervalSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initial.name);
  late IntervalType _type = widget.initial.type;
  late int _seconds = widget.initial.seconds;
  int _wheelKey = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<String> _suggestions(S s) {
    final used = AppScope.read(context).usedIntervalNames(_type);
    final out = <String>[];
    for (final n in [...used.take(6), ...NamePresets.forInterval(_type, s)]) {
      if (!out.contains(n)) out.add(n);
    }
    return out;
  }

  void _changeType(IntervalType t, S s) {
    final current = _name.text.trim();
    final wasDefault = current.isEmpty ||
        NamePresets.forInterval(_type, s).contains(current) ||
        current == s.typeName(_type);
    setState(() {
      if (wasDefault) _name.text = NamePresets.forInterval(t, s).first;
      _type = t;
    });
  }

  void _setSeconds(int v) => setState(() {
        _seconds = v;
        _wheelKey++;
      });

  WorkInterval _result(S s) => widget.initial.copyWith(
        name: _name.text.trim().isEmpty ? s.typeName(_type) : _name.text.trim(),
        seconds: _seconds < 1 ? 1 : _seconds,
        type: _type,
      );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TypeSelector(value: _type, onChanged: (t) => _changeType(t, s), labelOf: s.typeName),
        const SizedBox(height: 18),
        SectionLabel(s.name),
        const SizedBox(height: 8),
        AppTextField(controller: _name, hint: s.typeName(_type)),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: _name,
          builder: (context, _) => NameChips(
            names: _suggestions(s),
            selected: _name.text.trim(),
            onPick: (n) => _name.text = n,
          ),
        ),
        const SizedBox(height: 14),
        DurationWheel(key: ValueKey(_wheelKey), seconds: _seconds, onChanged: (v) => _seconds = v),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final q in const [20, 30, 45, 60, 120]) ...[
              if (q != 20) const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _setSeconds(q),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: c.s2,
                      foregroundColor: c.tx,
                      side: BorderSide(color: q == _seconds ? c.tx : c.line, width: q == _seconds ? 1.5 : 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(formatClock(q), style: T.display(17)),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: s.done,
          icon: null,
          color: Phase.fill(_type),
          foreground: Phase.on(_type),
          onPressed: () => Navigator.pop(context, IntervalSheetResult(IntervalAction.save, _result(s))),
        ),
        if (!widget.isNew) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: s.duplicate,
                  icon: AppIcons.copy,
                  onPressed: () => Navigator.pop(context, IntervalSheetResult(IntervalAction.duplicate, _result(s))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: s.delete,
                  icon: AppIcons.delete,
                  color: c.danger,
                  onPressed: () => Navigator.pop(context, IntervalSheetResult(IntervalAction.delete, widget.initial)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Minutes and seconds wheels.
class DurationWheel extends StatefulWidget {
  const DurationWheel({super.key, required this.seconds, required this.onChanged, this.maxMinutes = 99});

  final int seconds;
  final ValueChanged<int> onChanged;
  final int maxMinutes;

  @override
  State<DurationWheel> createState() => _DurationWheelState();
}

class _DurationWheelState extends State<DurationWheel> {
  late int _m = (widget.seconds ~/ 60).clamp(0, widget.maxMinutes);
  late int _s = widget.seconds % 60;
  late final _mc = FixedExtentScrollController(initialItem: _m);
  late final _sc = FixedExtentScrollController(initialItem: _s);

  @override
  void dispose() {
    _mc.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_m * 60 + _s);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = S.of(context);
    Widget wheel(FixedExtentScrollController ctrl, int count, ValueChanged<int> onSel, bool pad) => SizedBox(
          width: 96,
          child: CupertinoPicker.builder(
            scrollController: ctrl,
            itemExtent: 52,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: (i) {
              HapticFeedback.selectionClick();
              onSel(i);
              _emit();
            },
            childCount: count,
            itemBuilder: (context, i) => Center(
              child: Text(pad ? i.toString().padLeft(2, '0') : '$i', style: T.display(40, color: c.tx)),
            ),
          ),
        );
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 54, decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(14))),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              wheel(_mc, widget.maxMinutes + 1, (i) => _m = i, false),
              Text(':', style: T.display(40, color: c.tx)),
              wheel(_sc, 60, (i) => _s = i, true),
            ],
          ),
          Positioned(right: 4, child: Text(s.minSec, style: T.body(12, color: c.mu))),
        ],
      ),
    );
  }
}

/// Name something (block, workout) with ready-made names to pick from.
Future<String?> showNameSheet(
  BuildContext context, {
  required String title,
  required String initial,
  required List<String> presets,
}) {
  return _showSheet(context, _NameSheet(title: title, initial: initial, presets: presets));
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.title, required this.initial, required this.presets});
  final String title;
  final String initial;
  final List<String> presets;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _done() {
    final v = _ctrl.text.trim();
    Navigator.pop(context, v.isEmpty ? null : v);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(widget.title),
        const SizedBox(height: 8),
        AppTextField(controller: _ctrl, autofocus: true, onSubmitted: (_) => _done()),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) => NameChips(
            names: widget.presets,
            selected: _ctrl.text.trim(),
            onPick: (n) => _ctrl.text = n,
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: s.done, icon: null, onPressed: _done),
      ],
    );
  }
}

/// Pick a duration (quick start tiles).
Future<int?> showDurationSheet(BuildContext context, {required String title, required int seconds, Color? accent}) {
  var value = seconds;
  final s = S.of(context);
  return _showSheet(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title, color: accent),
        const SizedBox(height: 8),
        DurationWheel(seconds: seconds, onChanged: (v) => value = v),
        const SizedBox(height: 18),
        Builder(
          builder: (context) => PrimaryButton(
            label: s.done,
            icon: null,
            onPressed: () => Navigator.pop(context, value < 1 ? 1 : value),
          ),
        ),
      ],
    ),
  );
}

/// Pick a whole number (rounds, repeats).
Future<int?> showCountSheet(BuildContext context, {required String title, required int value, int min = 1, int max = 99}) {
  var current = value;
  final s = S.of(context);
  final c = AppColors.of(context);
  return _showSheet(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(height: 54, decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(14))),
              CupertinoPicker.builder(
                scrollController: FixedExtentScrollController(initialItem: value - min),
                itemExtent: 52,
                selectionOverlay: const SizedBox.shrink(),
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  current = i + min;
                },
                childCount: max - min + 1,
                itemBuilder: (context, i) => Center(child: Text('${i + min}', style: T.display(40, color: c.tx))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Builder(
          builder: (context) => PrimaryButton(
            label: s.done,
            icon: null,
            onPressed: () => Navigator.pop(context, current),
          ),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String message, required String confirm}) async {
  final s = S.of(context);
  final c = AppColors.of(context);
  final ok = await showDialog<bool>(
    context: context,
    animationStyle: AnimationStyle.noAnimation,
    builder: (context) => AlertDialog(
      title: Text(title, style: T.body(19, weight: 700, color: c.tx)),
      content: Text(message, style: T.body(15, color: c.mu)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel, style: T.body(15, weight: 600, color: c.tx))),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(confirm, style: T.body(15, weight: 700, color: c.danger))),
      ],
    ),
  );
  return ok ?? false;
}
