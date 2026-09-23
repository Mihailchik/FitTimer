import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/data/app_state.dart';
import 'package:flutter_timer/main.dart';
import 'package:flutter_timer/models/workout.dart';
import 'package:flutter_timer/models/settings.dart';
import 'package:flutter_timer/ui/screens/editor_screen.dart';
import 'package:flutter_timer/ui/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('quick start values survive reloading app state', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.updateSettings(state.settings.copyWith(
      quickWork: 47,
      quickRest: 23,
      quickRounds: 11,
    ));
    final reopened = await AppState.load();
    expect(reopened.settings.quickWork, 47);
    expect(reopened.settings.quickRest, 23);
    expect(reopened.settings.quickRounds, 11);
  });

  testWidgets('home shows quick start, templates and bottom navigation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Quick start'), findsOneWidget);
    expect(find.text('Tabata'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('templates live inside the compact quick start card',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();
    expect(
        find.ancestor(of: find.text('Tabata'), matching: find.byType(Surface)),
        findsOneWidget);
  });

  test('v1 sequence is migrated into the first workout', () async {
    SharedPreferences.setMockInitialValues({
      'timer_muted': true,
      'timer_sequence_v1': jsonEncode({
        'blocks': [
          {
            'name': 'Start block',
            'repeats': 3,
            'items': [
              {'name': 'Squats', 'duration': 45, 'isPause': false},
              {'name': 'Rest', 'duration': 15, 'isPause': true},
            ],
          },
        ],
      }),
    });
    final state = await AppState.load(migratedName: 'My workout');
    expect(state.workouts, hasLength(1));
    final w = state.workouts.single;
    expect(w.name, 'My workout');
    expect(w.blocks.single.repeats, 3);
    expect(w.blocks.single.intervals.map((i) => i.type),
        [IntervalType.work, IntervalType.rest]);
    expect(w.totalSeconds, 180);
    expect(state.settings.sound, isFalse);

    // Loading again must not duplicate the migrated workout.
    final again = await AppState.load();
    expect(again.workouts, hasLength(1));
  });

  testWidgets('a template can be added and opened for editing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.updateSettings(state.settings.copyWith(language: LanguageChoice.ru));
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tabata'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить и изменить'));
    await tester.pumpAndSettle();

    expect(state.workouts, hasLength(1));
    expect(state.workouts.single.name, 'Tabata');
    expect(state.workouts.single.blocks.single.repeats, 8);
    expect(find.byType(EditorScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Ещё').first);
    await tester.pumpAndSettle();
    expect(find.text('Удалить тренировку'), findsWidgets);
    expect(find.byType(PopupMenuButton), findsNothing);
  });

  testWidgets(
      'saved workout opens details and can be deleted with confirmation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    final workout = Workout.create(name: 'Custom plan', blocks: [
      WorkBlock.create(name: 'Main block', intervals: [
        WorkInterval.create(name: 'Squats', seconds: 30),
      ]),
    ]);
    state.saveWorkout(workout);
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details and edit'));
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);
    expect(find.text('Main block'), findsOneWidget);
    expect(find.text('Squats'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Delete workout'), 180,
        scrollable: find
            .descendant(
                of: find.byType(EditorScreen),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this workout?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(state.workouts, isEmpty);
  });

  testWidgets('history actions use the shared option sheet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.addHistory(HistoryEntry(
      workoutName: 'Test',
      startedAt: DateTime.now(),
      elapsedSeconds: 60,
      workSeconds: 40,
      restSeconds: 20,
      intervalsDone: 2,
      intervalsTotal: 2,
      completed: true,
    ));
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('Clear history'), findsOneWidget);
    expect(find.byType(PopupMenuButton), findsNothing);
  });

  testWidgets('single history entry can be renamed and deleted',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.addHistory(HistoryEntry(
      workoutName: 'Morning',
      startedAt: DateTime(2026, 9, 23, 8),
      elapsedSeconds: 90,
      workSeconds: 60,
      restSeconds: 30,
      intervalsDone: 3,
      intervalsTotal: 3,
      completed: true,
    ));
    await tester.pumpWidget(FitTimerApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning'));
    await tester.pumpAndSettle();
    expect(find.text('Workout details'), findsOneWidget);
    expect(find.text('1:30'), findsWidgets);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Evening');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(state.history.single.workoutName, 'Evening');
    expect((await AppState.load()).history.single.workoutName, 'Evening');
    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete entry'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this entry?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(state.history, isEmpty);
    expect((await AppState.load()).history, isEmpty);
  });
}
