import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sounds.dart';
import 'workout_runner.dart';

/// Turns runner cues into sound and vibration.
///
/// Each cue kind has its own preloaded player, so playing a cue is just
/// "rewind and resume" with no file work on the timer's hot path.
class CuePlayer {
  CuePlayer({required this.sound, required this.haptics, required this.duckMusic});

  bool sound;
  bool haptics;
  bool duckMusic;

  final Map<String, AudioPlayer> _players = {};
  bool _ready = false;

  static const _files = <String, Uint8List Function()>{
    'countdown': SoundSynth.countdown,
    'work': SoundSynth.workStart,
    'rest': SoundSynth.restStart,
    'half': SoundSynth.halfway,
    'finish': SoundSynth.finish,
  };

  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContextConfig(
        focus: duckMusic ? AudioContextConfigFocus.duckOthers : AudioContextConfigFocus.mixWithOthers,
      ).build());
      final dir = await Directory.systemTemp.createTemp('fittimer_cues');
      for (final entry in _files.entries) {
        final file = File('${dir.path}/${entry.key}.wav');
        await file.writeAsBytes(entry.value(), flush: true);
        final player = AudioPlayer(playerId: 'cue_${entry.key}');
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSourceDeviceFile(file.path);
        _players[entry.key] = player;
      }
      _ready = true;
    } catch (e) {
      debugPrint('CuePlayer init failed: $e');
    }
  }

  void play(Cue cue) {
    switch (cue.kind) {
      case CueKind.countdown:
        _sound('countdown');
        _vibrate(HapticFeedback.lightImpact);
      case CueKind.workStart:
        _sound('work');
        _vibrate(HapticFeedback.heavyImpact);
      case CueKind.restStart:
        _sound('rest');
        _vibrate(HapticFeedback.mediumImpact);
      case CueKind.halfway:
        _sound('half');
        _vibrate(HapticFeedback.selectionClick);
      case CueKind.finish:
        _sound('finish');
        _vibrate(HapticFeedback.heavyImpact);
    }
  }

  void _vibrate(Future<void> Function() fn) {
    if (haptics) fn();
  }

  Future<void> _sound(String key) async {
    if (!sound || !_ready) return;
    final p = _players[key];
    if (p == null) return;
    try {
      await p.stop();
      await p.seek(Duration.zero);
      await p.resume();
    } catch (e) {
      debugPrint('Cue $key failed: $e');
    }
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}
