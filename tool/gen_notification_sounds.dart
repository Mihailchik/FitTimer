// Writes the background-notification cue sounds into the iOS bundle.
// Run after changing lib/engine/sounds.dart:
//   dart run tool/gen_notification_sounds.dart
import 'dart:io';

import 'package:flutter_timer/engine/sounds.dart';

void main() {
  final out = {
    'cue_work.wav': SoundSynth.workStartWithCountdown(),
    'cue_rest.wav': SoundSynth.restStartWithCountdown(),
    'cue_finish.wav': SoundSynth.finishWithCountdown(),
  };
  for (final e in out.entries) {
    File('ios/Runner/Sounds/${e.key}').writeAsBytesSync(e.value);
    stdout.writeln('ios/Runner/Sounds/${e.key}  ${e.value.length} bytes');
  }
}
