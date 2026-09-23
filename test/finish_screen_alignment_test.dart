import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/models/workout.dart';
import 'package:flutter_timer/ui/screens/finish_screen.dart';
import 'package:flutter_timer/ui/theme.dart';
import 'package:flutter_timer/ui/widgets/common.dart';

void main() {
  testWidgets('finish statistics share one right alignment', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: FinishScreen(
        summary: RunSummary(
          workout: Workout.create(name: 'HIIT'),
          elapsed: const Duration(minutes: 3, seconds: 45),
          work: const Duration(minutes: 2, seconds: 45),
          rest: const Duration(minutes: 1),
          intervalsDone: 5,
          intervalsTotal: 8,
          early: false,
        ),
      ),
    ));

    final ends = [
      for (final value in ['3:45', '5 of 8', '2:45', '1:00'])
        tester.getTopRight(find.text(value)).dx,
    ];
    for (final end in ends.skip(1)) {
      expect((end - ends.first).abs(), lessThan(1));
    }

    final repeatButton = find.byType(OutlinedButton);
    final doneButton = find.byType(FilledButton);
    final repeatLabel = find.text('Repeat');
    final doneLabel = find.text('Done');
    expect(tester.getSize(repeatButton).height, tester.getSize(doneButton).height);
    expect(tester.getSize(doneButton).height, AppLayout.actionHeight);
    expect(
      (tester.getCenter(repeatButton).dx - tester.getCenter(repeatLabel).dx)
          .abs(),
      lessThan(1),
    );
    expect(
      (tester.getCenter(doneButton).dx - tester.getCenter(doneLabel).dx).abs(),
      lessThan(1),
    );
    final repeatStyle =
        DefaultTextStyle.of(tester.element(repeatLabel)).style;
    final doneStyle = DefaultTextStyle.of(tester.element(doneLabel)).style;
    expect(repeatStyle.fontSize, doneStyle.fontSize);
    expect(repeatStyle.fontWeight, doneStyle.fontWeight);
    expect(repeatStyle.fontFamily, doneStyle.fontFamily);

    final report = tester.getRect(find.byType(Surface));
    final repeat = tester.getRect(repeatButton);
    final done = tester.getRect(doneButton);
    expect((report.left - repeat.left).abs(), lessThan(1));
    expect((report.right - done.right).abs(), lessThan(1));

    final reportRadius = tester.widget<Surface>(find.byType(Surface)).radius;
    final doneShape = tester.widget<FilledButton>(doneButton)
        .style!
        .shape!
        .resolve({})! as RoundedRectangleBorder;
    expect(doneShape.borderRadius.resolve(TextDirection.ltr).topLeft.x,
        reportRadius);
  });
}
