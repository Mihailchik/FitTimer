import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timer/ui/icons.dart';
import 'package:flutter_timer/ui/theme.dart';
import 'package:flutter_timer/ui/widgets/common.dart';

void main() {
  testWidgets('primary and secondary labels stay centered with leading icons',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PrimaryButton(label: 'Старт', onPressed: () {}),
              SecondaryButton(
                  label: 'Заново',
                  icon: AppIcons.restart,
                  onPressed: () {}),
            ]),
          ),
        ),
      ),
    ));

    final primaryCenter = tester.getCenter(find.byType(FilledButton));
    final primaryLabelCenter = tester.getCenter(find.text('Старт'));
    final secondaryCenter = tester.getCenter(find.byType(OutlinedButton));
    final secondaryLabelCenter = tester.getCenter(find.text('Заново'));

    expect((primaryCenter.dx - primaryLabelCenter.dx).abs(), lessThan(1));
    expect((secondaryCenter.dx - secondaryLabelCenter.dx).abs(), lessThan(1));
    final labelStyle =
        DefaultTextStyle.of(tester.element(find.text('Старт'))).style;
    final labelMeasure = TextPainter(
      text: TextSpan(text: 'Старт', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(
      primaryLabelCenter.dx -
          labelMeasure.width / 2 -
          tester.getTopRight(find.byIcon(AppIcons.play)).dx,
      inInclusiveRange(4, 16),
    );
  });
}
