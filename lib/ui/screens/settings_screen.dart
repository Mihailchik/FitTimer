import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../l10n/strings.dart';
import '../../models/settings.dart';
import '../theme.dart';
import '../icons.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final st = app.settings;
    void set(AppSettings v) => app.updateSettings(v);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppLayout.pageInset, 16, AppLayout.pageInset, 32),
        children: [
          ScreenTitle(s.settings),
          const SizedBox(height: 20),
          _Group(title: s.soundAndHaptics, rows: [
            _Toggle(label: s.sounds, value: st.sound, onChanged: (v) => set(st.copyWith(sound: v))),
            _Toggle(label: s.duckMusic, hint: s.duckMusicHint, value: st.duckMusic, onChanged: (v) => set(st.copyWith(duckMusic: v))),
            _Toggle(label: s.vibration, value: st.haptics, onChanged: (v) => set(st.copyWith(haptics: v))),
          ]),
          _Group(title: s.training, rows: [
            _Choice<int>(
              label: s.prepBeforeStart,
              value: st.prepSeconds,
              options: const [0, 5, 10, 15, 20],
              labelOf: (v) => v == 0 ? s.off : formatClock(v),
              onChanged: (v) => set(st.copyWith(prepSeconds: v)),
            ),
            _Toggle(label: s.keepAwake, value: st.keepAwake, onChanged: (v) => set(st.copyWith(keepAwake: v))),
            _Toggle(label: s.halfwayCue, hint: s.halfwayCueHint, value: st.halfwayCue, onChanged: (v) => set(st.copyWith(halfwayCue: v))),
          ]),
          _Group(title: s.general, rows: [
            _Choice<LanguageChoice>(
              label: s.language,
              value: st.language,
              options: LanguageChoice.values,
              labelOf: (v) => switch (v) {
                LanguageChoice.system => s.langSystem,
                LanguageChoice.ru => 'Русский',
                LanguageChoice.en => 'English',
              },
              onChanged: (v) => set(st.copyWith(language: v)),
            ),
            _Choice<ThemeChoice>(
              label: s.theme,
              value: st.theme,
              options: ThemeChoice.values,
              labelOf: (v) => switch (v) {
                ThemeChoice.light => s.themeLight,
                ThemeChoice.dark => s.themeDark,
                ThemeChoice.system => s.themeSystem,
              },
              onChanged: (v) => set(st.copyWith(theme: v)),
            ),
          ]),
          const SizedBox(height: 8),
          Center(child: Text('FitTimer 2.0', style: T.body(12, color: AppColors.of(context).mu))),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: SectionLabel(title)),
          Surface(
            radius: 18,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.value, required this.onChanged, this.hint});
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MergeSemantics(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: T.body(15, weight: 600, color: c.tx)),
                      if (hint != null) Text(hint!, style: T.body(12.5, color: c.mu)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: Phase.work,
                  activeThumbColor: Phase.onWork,
                  inactiveTrackColor: c.switchOff,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice<V> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final V value;
  final List<V> options;
  final String Function(V) labelOf;
  final ValueChanged<V> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: '$label: ${labelOf(value)}',
      child: InkWell(
        onTap: () async {
          final chosen = await showOptionSheet<V>(
            context,
            title: label,
            selected: value,
            items: [for (final o in options) OptionSheetItem(o, labelOf(o))],
          );
          if (chosen != null && context.mounted) onChanged(chosen);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                Expanded(child: Text(label, style: T.body(15, weight: 600, color: c.tx))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.s2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(labelOf(value), style: T.body(14, weight: 600, color: c.tx)),
                      const SizedBox(width: 7),
                      Icon(AppIcons.chevronDown, size: 14, color: c.mu),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
