import 'package:flutter/material.dart';

import '../models/workout.dart';

/// Phase fills are the same in both themes: the run screen is painted with them.
class Phase {
  static const work = Color(0xFFC8F03C);
  static const rest = Color(0xFF5AB0FF);
  static const prep = Color(0xFFFFB23E);
  static const onWork = Color(0xFF10120B);
  static const onRest = Color(0xFF07121F);
  static const onPrep = Color(0xFF1A1204);
  static const darkWork = Color(0xFF19230D);
  static const darkRest = Color(0xFF0D2032);
  static const darkPrep = Color(0xFF2B1D0C);

  static Color darkFill(IntervalType t) => switch (t) {
        IntervalType.work => darkWork,
        IntervalType.rest => darkRest,
        IntervalType.prep => darkPrep,
      };

  static Color fill(IntervalType t) => switch (t) {
        IntervalType.work => work,
        IntervalType.rest => rest,
        IntervalType.prep => prep,
      };

  static Color on(IntervalType t) => switch (t) {
        IntervalType.work => onWork,
        IntervalType.rest => onRest,
        IntervalType.prep => onPrep,
      };
}

class AppLayout {
  static const double pageInset = 20;
  static const double cardRadius = 18;
  static const double actionHeight = 56;
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg,
      s1,
      s2,
      line,
      tx,
      mu,
      work,
      rest,
      prep,
      navActive,
      row,
      chip,
      grip,
      dash,
      danger,
      faint,
      switchOff,
      bar;

  const AppColors({
    required this.bg,
    required this.s1,
    required this.s2,
    required this.line,
    required this.tx,
    required this.mu,
    required this.work,
    required this.rest,
    required this.prep,
    required this.navActive,
    required this.row,
    required this.chip,
    required this.grip,
    required this.dash,
    required this.danger,
    required this.faint,
    required this.switchOff,
    required this.bar,
  });

  static const light = AppColors(
    bg: Color(0xFFF2F2F7),
    s1: Color(0xFFFFFFFF),
    s2: Color(0xFFF2F2F7),
    line: Color(0xFFE5E5EA),
    tx: Color(0xFF000000),
    mu: Color(0xFF6C6C70),
    work: Color(0xFF3A6B00),
    rest: Color(0xFF0A66C2),
    prep: Color(0xFF9A5B00),
    navActive: Color(0xFF3A6B00),
    row: Color(0xFFF7F7FA),
    chip: Color(0xFFE9E9EE),
    grip: Color(0xFFC7C7CC),
    dash: Color(0xFFC7C7CC),
    danger: Color(0xFFD70015),
    faint: Color(0xFFC7C7CC),
    switchOff: Color(0xFFE9E9EA),
    bar: Color(0xF2F9F9F9),
  );

  static const dark = AppColors(
    bg: Color(0xFF000000),
    s1: Color(0xFF1C1C1E),
    s2: Color(0xFF2C2C2E),
    line: Color(0xFF38383A),
    tx: Color(0xFFFFFFFF),
    mu: Color(0xFF98989F),
    work: Color(0xFFC8F03C),
    rest: Color(0xFF64B5FF),
    prep: Color(0xFFFFB23E),
    navActive: Color(0xFFC8F03C),
    row: Color(0xFF242426),
    chip: Color(0xFF2C2C2E),
    grip: Color(0xFF636366),
    dash: Color(0xFF48484A),
    danger: Color(0xFFFF6961),
    faint: Color(0xFF48484A),
    switchOff: Color(0xFF39393D),
    bar: Color(0xF01C1C1E),
  );

  Color typeText(IntervalType t) => switch (t) {
        IntervalType.work => work,
        IntervalType.rest => rest,
        IntervalType.prep => prep,
      };

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// Text helpers. The app uses the platform font (San Francisco on iOS);
/// even leading keeps labels optically centred inside buttons.
class T {
  static TextStyle display(double size,
          {Color? color,
          double weight = 700,
          double? height,
          double? spacing}) =>
      TextStyle(
        fontSize: size,
        fontWeight: _w(weight),
        color: color,
        height: height,
        letterSpacing: spacing,
        leadingDistribution: TextLeadingDistribution.even,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle body(double size,
          {Color? color,
          double weight = 500,
          double? height,
          double? spacing}) =>
      TextStyle(
        fontSize: size,
        fontWeight: _w(weight),
        color: color,
        height: height,
        letterSpacing: spacing,
        leadingDistribution: TextLeadingDistribution.even,
      );

  /// Section headers use one readable size across every screen.
  static TextStyle label(Color color) =>
      body(18, color: color, weight: 700, height: 1.2);

  static FontWeight _w(double w) =>
      FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Phase.work,
      brightness: brightness,
      surface: c.s1,
      primary: c.work,
      onSurface: c.tx,
    ),
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    dividerColor: c.line,
    bottomSheetTheme: BottomSheetThemeData(
      constraints: const BoxConstraints(maxWidth: 640),
      backgroundColor: c.s1,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.dash,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
        backgroundColor: c.s1, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.tx,
      contentTextStyle: T.body(14, color: c.bg),
    ),
  );
}
