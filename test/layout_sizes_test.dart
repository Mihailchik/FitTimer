import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/data/app_state.dart';
import 'package:flutter_timer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screens must not overflow on the smallest iPhone, on iPad in both
/// orientations, or with large accessibility text.
const _sizes = {
  'iPhone SE 1st gen': Size(320, 568),
  'iPhone SE 2/3': Size(375, 667),
  'iPhone 17 Pro': Size(402, 874),
  'iPad 13 portrait': Size(1032, 1376),
  'iPad 13 landscape': Size(1376, 1032),
};

void main() {
  for (final entry in _sizes.entries) {
    for (final scale in [1.0, 1.35, 2.0]) {
      testWidgets('${entry.key}, text x$scale: no overflow', (tester) async {
        SharedPreferences.setMockInitialValues({'v2_settings': '{"keepAwake":false,"language":"ru"}'});
        final state = await AppState.load();
        tester.view.physicalSize = entry.value * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
        addTearDown(() => FlutterError.onError = previous);

        await tester.pumpWidget(FitTimerApp(state: state));
        await tester.pumpAndSettle();
        for (final tab in ['История', 'Настройки', 'Тренировки']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Tabata').first);
        await tester.pumpAndSettle();

        expect(errors, isEmpty);
      });
    }
  }
}
