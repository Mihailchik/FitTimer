import 'package:flutter/widgets.dart';

/// Every icon the app uses, from one family (Phosphor, MIT; font files in
/// assets/fonts) so stroke weight, corner radius and optical size match.
/// Swap the set here, nowhere else.
class AppIcons {
  static const _bold = 'PhosphorBold';
  static const _fill = 'PhosphorFill';

  static const IconData add = IconData(0xe3d4, fontFamily: _bold);
  static const IconData minus = IconData(0xe32a, fontFamily: _bold);
  static const IconData close = IconData(0xe4f6, fontFamily: _bold);
  static const IconData clear = IconData(0xe4f8, fontFamily: _fill);
  static const IconData back = IconData(0xe138, fontFamily: _bold);
  static const IconData more = IconData(0xe1fe, fontFamily: _bold);
  static const IconData moreVertical = IconData(0xe208, fontFamily: _bold);
  static const IconData chooser = IconData(0xe140, fontFamily: _bold);
  static const IconData chevronDown = IconData(0xe136, fontFamily: _bold);
  static const IconData check = IconData(0xe182, fontFamily: _bold);
  static const IconData edit = IconData(0xe3b4, fontFamily: _bold);
  static const IconData copy = IconData(0xe1ca, fontFamily: _bold);
  static const IconData delete = IconData(0xe4a6, fontFamily: _bold);
  static const IconData drag = IconData(0xeae2, fontFamily: _bold);

  static const IconData play = IconData(0xe3d0, fontFamily: _fill);
  static const IconData pause = IconData(0xe39e, fontFamily: _fill);
  static const IconData skipBack = IconData(0xe5a4, fontFamily: _fill);
  static const IconData skipForward = IconData(0xe5a6, fontFamily: _fill);
  static const IconData restart = IconData(0xe038, fontFamily: _bold);
  static const IconData finish = IconData(0xe244, fontFamily: _fill);
  static const IconData soundOn = IconData(0xe44a, fontFamily: _fill);
  static const IconData soundOff = IconData(0xe45a, fontFamily: _fill);

  static const IconData tabWorkouts = IconData(0xe492, fontFamily: _bold);
  static const IconData tabWorkoutsActive = IconData(0xe492, fontFamily: _fill);
  static const IconData tabHistory = IconData(0xe150, fontFamily: _bold);
  static const IconData tabHistoryActive = IconData(0xe150, fontFamily: _fill);
  static const IconData tabSettings = IconData(0xe270, fontFamily: _bold);
  static const IconData tabSettingsActive = IconData(0xe270, fontFamily: _fill);
}
