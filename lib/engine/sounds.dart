import 'dart:math';
import 'dart:typed_data';

/// Synthesises the timer's cue sounds as 16-bit mono WAV files.
///
/// Every note gets a short attack and an exponential decay so the cues sound
/// like soft electronic bells instead of the raw clicking sine of v1.
class SoundSynth {
  static const sampleRate = 44100;

  static const _countdownNotes = [_Note(880, 0, 110)];
  static const _workNotes = [_Note(880, 0, 120), _Note(1318.5, 110, 320)];
  static const _restNotes = [_Note(1046.5, 0, 140), _Note(659.3, 130, 360)];
  static const _halfNotes = [_Note(784, 0, 90), _Note(784, 140, 90)];
  static const _finishNotes = [
    _Note(523.3, 0, 180),
    _Note(659.3, 140, 180),
    _Note(784, 280, 180),
    _Note(1046.5, 420, 520),
  ];

  static Uint8List countdown() => _render(_countdownNotes, gain: 0.55);
  static Uint8List workStart() => _render(_workNotes, gain: 0.7);
  static Uint8List restStart() => _render(_restNotes, gain: 0.6);
  static Uint8List halfway() => _render(_halfNotes, gain: 0.5);
  static Uint8List finish() => _render(_finishNotes, gain: 0.65);

  /// "3, 2, 1" ticks one second apart followed by the cue, for notifications
  /// that fire three seconds before an interval changes while the app is in
  /// the background.
  static Uint8List workStartWithCountdown() => _withCountdown(_workNotes);
  static Uint8List restStartWithCountdown() => _withCountdown(_restNotes);
  static Uint8List finishWithCountdown() => _withCountdown(_finishNotes);

  static Uint8List _withCountdown(List<_Note> cue) => _render([
        for (final t in const [0, 1000, 2000]) _Note(880, t, 110, 0.7),
        for (final n in cue) _Note(n.freq, n.startMs + 3000, n.lengthMs),
      ], gain: 0.7);

  static Uint8List _render(List<_Note> notes, {required double gain}) {
    final endMs = notes.map((n) => n.startMs + n.lengthMs).reduce(max);
    final total = (sampleRate * (endMs + 30) / 1000).round();
    final mix = Float64List(total);
    for (final n in notes) {
      final start = (sampleRate * n.startMs / 1000).round();
      final len = (sampleRate * n.lengthMs / 1000).round();
      final attack = (sampleRate * 0.004).round();
      for (var i = 0; i < len && start + i < total; i++) {
        final t = i / sampleRate;
        final env = (i < attack ? i / attack : 1.0) * exp(-5.0 * i / len);
        final wave = sin(2 * pi * n.freq * t) + 0.25 * sin(4 * pi * n.freq * t);
        mix[start + i] += wave * env * n.amp;
      }
    }
    var peak = 0.0;
    for (final v in mix) {
      peak = max(peak, v.abs());
    }
    final scale = peak == 0 ? 0 : gain / peak;
    final pcm = ByteData(total * 2);
    for (var i = 0; i < total; i++) {
      pcm.setInt16(i * 2, (mix[i] * scale * 32767).round().clamp(-32768, 32767), Endian.little);
    }
    return _wav(pcm.buffer.asUint8List());
  }

  static Uint8List _wav(Uint8List pcm) {
    final h = ByteData(44);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        h.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    h.setUint32(4, 36 + pcm.length, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little); // PCM
    h.setUint16(22, 1, Endian.little); // mono
    h.setUint32(24, sampleRate, Endian.little);
    h.setUint32(28, sampleRate * 2, Endian.little);
    h.setUint16(32, 2, Endian.little);
    h.setUint16(34, 16, Endian.little);
    str(36, 'data');
    h.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...h.buffer.asUint8List(), ...pcm]);
  }
}

class _Note {
  final double freq;
  final int startMs;
  final int lengthMs;
  final double amp;
  const _Note(this.freq, this.startMs, this.lengthMs, [this.amp = 1.0]);
}
