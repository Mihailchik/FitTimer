import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../icons.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'history_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: PageWidth(
        child: IndexedStack(
          index: _tab,
          children: const [LibraryScreen(), HistoryScreen(), SettingsScreen()],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        selectedIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
        labels: [s.workouts, s.history, s.settings],
      ),
    );
  }
}

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.labels,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<String> labels;

  static const icons = [
    AppIcons.tabWorkouts,
    AppIcons.tabHistory,
    AppIcons.tabSettings,
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.s1,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppLayout.pageInset, 8, AppLayout.pageInset, 8),
          child: Row(
            children: [
              for (var i = 0; i < icons.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: icons[i],
                    label: labels[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? c.navActive : c.mu;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? c.chip : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(child: Icon(icon, size: 24, color: color)),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 17,
                  child: Center(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            T.body(13, weight: 600, color: color, height: 1)),
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
