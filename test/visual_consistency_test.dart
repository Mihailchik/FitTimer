import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/data/app_state.dart';
import 'package:flutter_timer/main.dart';
import 'package:flutter_timer/models/settings.dart';
import 'package:flutter_timer/ui/screens/home_shell.dart';
import 'package:flutter_timer/ui/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('page navigation uses one motion rule', () {
    final route = appRoute<void>((_) => const SizedBox());
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
  });

  testWidgets('home headings and navigation share a consistent scale',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.updateSettings(state.settings.copyWith(language: LanguageChoice.en));
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();

    final tab = find.byType(AppBottomBar);
    final icons = tester.widgetList<Icon>(
      find.descendant(of: tab, matching: find.byType(Icon)),
    );
    expect(icons.map((icon) => icon.icon!.fontFamily).toSet(), hasLength(1));
    expect(icons.map((icon) => icon.size).toSet(), {24.0});

    final heading = tester.widget<Text>(find.text('My workouts'));
    expect(heading.style!.fontSize, 18);
    expect(find.ancestor(of: find.text('Quick workouts'), matching: find.byType(Surface)),
        findsOneWidget);

    final iconCenters = [for (final icon in find.descendant(of: tab, matching: find.byType(Icon)).evaluate())
      tester.getCenter(find.byWidget(icon.widget))];
    final labelCenters = [
      for (final label in ['Workouts', 'History', 'Settings'])
        tester.getCenter(find.descendant(of: tab, matching: find.text(label))),
    ];
    for (final center in iconCenters.skip(1)) {
      expect((center.dy - iconCenters.first.dy).abs(), lessThan(1));
    }
    for (var i = 0; i < iconCenters.length; i++) {
      expect((iconCenters[i].dx - labelCenters[i].dx).abs(), lessThan(1));
      expect((labelCenters[i].dy - labelCenters.first.dy).abs(), lessThan(1));
    }
  });
}
