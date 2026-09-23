import '../models/workout.dart';

/// One step of a running workout: an interval with its position in the plan.
class Segment {
  final IntervalType type;
  final String name;
  final int seconds;
  final int blockIndex;
  final String blockName;
  final int round; // 1-based
  final int rounds;

  const Segment({
    required this.type,
    required this.name,
    required this.seconds,
    required this.blockIndex,
    required this.blockName,
    required this.round,
    required this.rounds,
  });

  Duration get duration => Duration(seconds: seconds);
}

/// Flattens a workout into the exact sequence the runner plays.
///
/// A preparation segment is added in front when [prepSeconds] > 0; it carries
/// the name of the first real interval so the screen can say what is coming.
/// Intervals with zero length are skipped.
List<Segment> buildTimeline(Workout workout, {int prepSeconds = 0, String prepName = ''}) {
  final out = <Segment>[];
  for (var b = 0; b < workout.blocks.length; b++) {
    final block = workout.blocks[b];
    for (var r = 1; r <= block.repeats; r++) {
      for (final interval in block.intervals) {
        if (interval.seconds <= 0) continue;
        out.add(Segment(
          type: interval.type,
          name: interval.name,
          seconds: interval.seconds,
          blockIndex: b,
          blockName: block.name,
          round: r,
          rounds: block.repeats,
        ));
      }
    }
  }
  if (prepSeconds > 0 && out.isNotEmpty && out.first.type != IntervalType.prep) {
    final first = out.first;
    out.insert(
      0,
      Segment(
        type: IntervalType.prep,
        name: prepName,
        seconds: prepSeconds,
        blockIndex: first.blockIndex,
        blockName: first.blockName,
        round: first.round,
        rounds: first.rounds,
      ),
    );
  }
  return out;
}
