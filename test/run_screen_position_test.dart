import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/data/app_state.dart';
import 'package:flutter_timer/models/workout.dart';
import 'package:flutter_timer/ui/screens/run_screen.dart';
import 'package:flutter_timer/ui/icons.dart';
import 'package:flutter_timer/ui/theme.dart';
import 'package:flutter_timer/ui/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('timer controls describe their actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = await AppState.load();
    app.updateSettings(app.settings.copyWith(
      prepSeconds: 0,
      sound: false,
      haptics: false,
      keepAwake: false,
      backgroundCues: false,
    ));
    final workout = Workout.create(name: 'Test', blocks: [
      WorkBlock.create(name: 'Block', intervals: [
        WorkInterval.create(name: 'Work', seconds: 30),
      ]),
    ]);
    await tester.pumpWidget(AppScope(
      state: app,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: RunScreen(workout: workout),
      ),
    ));
    await tester.pump();

    final topPause = find.byWidgetPredicate(
        (widget) => widget is RoundIconButton && widget.tooltip == 'Pause and actions');
    expect(topPause, findsOneWidget);
    expect(find.descendant(of: topPause, matching: find.byIcon(AppIcons.pause)),
        findsOneWidget);
    expect(find.byTooltip('Turn sound on'), findsOneWidget);
    await tester.tap(find.byTooltip('Turn sound on'));
    await tester.pump();
    expect(find.byTooltip('Turn sound off'), findsOneWidget);
    await tester.tap(topPause);
    await tester.pump();
    expect(find.byTooltip('Resume'), findsWidgets);
  });

  testWidgets('timer uses distinct readable dark palette', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = await AppState.load();
    app.updateSettings(app.settings.copyWith(
        prepSeconds: 0, sound: false, haptics: false, keepAwake: false));
    final workout = Workout.create(name: 'Test', blocks: [
      WorkBlock.create(name: 'Block', intervals: [
        WorkInterval.create(name: 'Work', seconds: 30),
      ]),
    ]);
    Future<Color?> background(Brightness brightness) async {
      await tester.pumpWidget(AppScope(
          state: app,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: RunScreen(workout: workout),
          )));
      await tester.pump(const Duration(milliseconds: 500));
      return (tester
              .widget<AnimatedContainer>(find.byType(AnimatedContainer))
              .decoration as BoxDecoration?)
          ?.color;
    }

    final light = await background(Brightness.light);
    final dark = await background(Brightness.dark);
    expect(dark, isNot(light));
  });

  testWidgets('pause preserves ring geometry', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final app = await AppState.load();
    app.updateSettings(app.settings.copyWith(
      prepSeconds: 0,
      sound: false,
      haptics: false,
      keepAwake: false,
    ));
    final workout = Workout.create(name: 'Test', blocks: [
      WorkBlock.create(name: 'Block', intervals: [
        WorkInterval.create(name: 'Work', seconds: 30),
      ]),
    ]);
    await tester.pumpWidget(AppScope(
      state: app,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: RunScreen(workout: workout),
      ),
    ));
    await tester.pump();
    final ring = find.byWidgetPredicate((w) =>
        w is CustomPaint && w.painter.runtimeType.toString() == '_RingPainter');
    final before = tester.getRect(ring);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    final after = tester.getRect(ring.last);
    expect(after, before);
    final topResume = find.byWidgetPredicate(
        (widget) => widget is RoundIconButton && widget.tooltip == 'Resume');
    final topPlay =
        find.descendant(of: topResume, matching: find.byIcon(AppIcons.play));
    expect(
        (tester.getCenter(topPlay).dx - tester.getCenter(topResume).dx).abs(),
        lessThan(0.5));
    final restart = find.text('Restart');
    final end = find.text('End workout');
    final restartButton =
        find.ancestor(of: restart, matching: find.byType(OutlinedButton));
    final endButton =
        find.ancestor(of: end, matching: find.byType(OutlinedButton));
    expect(tester.getRect(restartButton).size, tester.getRect(endButton).size);
    expect(
        (tester.getCenter(restart).dx - tester.getCenter(restartButton).dx)
            .abs(),
        lessThan(1));
    expect((tester.getCenter(end).dx - tester.getCenter(endButton).dx).abs(),
        lessThan(1));
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(tester.getRect(ring), before);
  });

  testWidgets('timer stays in place when a phase label appears',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = await AppState.load();
    app.updateSettings(app.settings.copyWith(
      prepSeconds: 0,
      sound: false,
      haptics: false,
      keepAwake: false,
    ));
    final workout = Workout.create(
      name: 'Test',
      blocks: [
        WorkBlock.create(name: 'Block', intervals: [
          WorkInterval.create(name: 'Work', seconds: 30),
          WorkInterval.create(name: 'Squats', seconds: 30),
          WorkInterval.create(
              name: 'A deliberately long two-line exercise name', seconds: 30),
        ]),
      ],
    );

    await tester.pumpWidget(AppScope(
      state: app,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: RunScreen(workout: workout),
      ),
    ));
    await tester.pump();

    final before = tester.getCenter(find.text('30')).dy;
    await tester.tap(find.byTooltip('Next interval'));
    await tester.pump();
    final after = tester.getCenter(find.text('30')).dy;

    expect(find.text('Squats'), findsOneWidget);
    expect((after - before).abs(), lessThan(1));

    await tester.tap(find.byTooltip('Next interval'));
    await tester.pump();
    final afterLongName = tester.getCenter(find.text('30')).dy;
    expect((afterLongName - before).abs(), lessThan(1));
  });
}
