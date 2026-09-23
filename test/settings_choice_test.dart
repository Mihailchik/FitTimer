import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/data/app_state.dart';
import 'package:flutter_timer/main.dart';
import 'package:flutter_timer/models/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('language is chosen from the shared option sheet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuButton), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Language'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(state.settings.language, LanguageChoice.ru);
    expect(find.text('Язык'), findsOneWidget);
  });
}
