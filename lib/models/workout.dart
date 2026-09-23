enum IntervalType { work, rest, prep }

IntervalType _typeFromName(String? name) {
  return IntervalType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => IntervalType.work,
  );
}

int _idCounter = 0;

/// Short unique id, good enough for local storage.
String newId() {
  _idCounter = (_idCounter + 1) % 1000;
  return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
}

class WorkInterval {
  final String id;
  final String name;
  final int seconds;
  final IntervalType type;

  const WorkInterval({
    required this.id,
    required this.name,
    required this.seconds,
    required this.type,
  });

  factory WorkInterval.create({
    required String name,
    required int seconds,
    IntervalType type = IntervalType.work,
  }) =>
      WorkInterval(id: newId(), name: name, seconds: seconds, type: type);

  WorkInterval copyWith({String? name, int? seconds, IntervalType? type}) {
    return WorkInterval(
      id: id,
      name: name ?? this.name,
      seconds: seconds ?? this.seconds,
      type: type ?? this.type,
    );
  }

  WorkInterval duplicate() => copyWith().withNewId();

  WorkInterval withNewId() =>
      WorkInterval(id: newId(), name: name, seconds: seconds, type: type);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'seconds': seconds,
        'type': type.name,
      };

  factory WorkInterval.fromJson(Map<String, dynamic> json) => WorkInterval(
        id: (json['id'] as String?) ?? newId(),
        name: (json['name'] as String?) ?? '',
        seconds: (json['seconds'] as num?)?.toInt() ?? 30,
        type: _typeFromName(json['type'] as String?),
      );
}

class WorkBlock {
  final String id;
  final String name;
  final int repeats;
  final List<WorkInterval> intervals;

  const WorkBlock({
    required this.id,
    required this.name,
    required this.repeats,
    required this.intervals,
  });

  factory WorkBlock.create({
    required String name,
    int repeats = 1,
    List<WorkInterval> intervals = const [],
  }) =>
      WorkBlock(id: newId(), name: name, repeats: repeats, intervals: intervals);

  int get secondsPerRound => intervals.fold(0, (sum, i) => sum + i.seconds);
  int get totalSeconds => secondsPerRound * repeats;
  int get intervalCount => intervals.length * repeats;

  WorkBlock copyWith({String? name, int? repeats, List<WorkInterval>? intervals}) {
    return WorkBlock(
      id: id,
      name: name ?? this.name,
      repeats: repeats ?? this.repeats,
      intervals: intervals ?? this.intervals,
    );
  }

  WorkBlock duplicate() => WorkBlock(
        id: newId(),
        name: name,
        repeats: repeats,
        intervals: intervals.map((i) => i.withNewId()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'repeats': repeats,
        'intervals': intervals.map((i) => i.toJson()).toList(),
      };

  factory WorkBlock.fromJson(Map<String, dynamic> json) => WorkBlock(
        id: (json['id'] as String?) ?? newId(),
        name: (json['name'] as String?) ?? '',
        repeats: ((json['repeats'] as num?)?.toInt() ?? 1).clamp(1, 99),
        intervals: ((json['intervals'] as List?) ?? const [])
            .map((e) => WorkInterval.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Workout {
  final String id;
  final String name;
  final List<WorkBlock> blocks;
  final DateTime updatedAt;

  const Workout({
    required this.id,
    required this.name,
    required this.blocks,
    required this.updatedAt,
  });

  factory Workout.create({required String name, List<WorkBlock> blocks = const []}) =>
      Workout(id: newId(), name: name, blocks: blocks, updatedAt: DateTime.now());

  int get totalSeconds => blocks.fold(0, (sum, b) => sum + b.totalSeconds);
  int get intervalCount => blocks.fold(0, (sum, b) => sum + b.intervalCount);
  bool get isEmpty => totalSeconds == 0;

  Workout copyWith({String? name, List<WorkBlock>? blocks}) {
    return Workout(
      id: id,
      name: name ?? this.name,
      blocks: blocks ?? this.blocks,
      updatedAt: DateTime.now(),
    );
  }

  Workout duplicate(String newName) => Workout(
        id: newId(),
        name: newName,
        blocks: blocks.map((b) => b.duplicate()).toList(),
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'updatedAt': updatedAt.toIso8601String(),
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: (json['id'] as String?) ?? newId(),
        name: (json['name'] as String?) ?? '',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        blocks: ((json['blocks'] as List?) ?? const [])
            .map((e) => WorkBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
