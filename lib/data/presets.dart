import '../l10n/strings.dart';
import '../models/workout.dart';

/// Ready-made names offered as chips when creating or renaming things.
class NamePresets {
  static List<String> forInterval(IntervalType type, S s) => switch (type) {
        IntervalType.work => s.ru ? _workRu : _workEn,
        IntervalType.rest => s.ru ? const ['Отдых', 'Пауза', 'Вода', 'Смена снаряда'] : const ['Rest', 'Break', 'Water', 'Switch'],
        IntervalType.prep => s.ru ? const ['Подготовка', 'Разминка', 'Настройся'] : const ['Get ready', 'Warm-up', 'Set up'],
      };

  static List<String> forBlock(S s) => s.ru
      ? const ['Разминка', 'Круг', 'Основной блок', 'Кардио', 'Сила', 'Пресс', 'Ноги', 'Финишер', 'Заминка', 'Растяжка']
      : const ['Warm-up', 'Circuit', 'Main set', 'Cardio', 'Strength', 'Core', 'Legs', 'Finisher', 'Cool-down', 'Stretch'];

  static List<String> forWorkout(S s) => s.ru
      ? const ['Утренняя', 'Круговая', 'Кардио', 'Ноги и корпус', 'Всё тело', 'Пресс', 'Растяжка']
      : const ['Morning', 'Circuit', 'Cardio', 'Legs & core', 'Full body', 'Abs', 'Stretch'];

  static const _workRu = [
    'Бёрпи', 'Приседания', 'Отжимания', 'Планка', 'Выпады', 'Скакалка', 'Прыжки на месте',
    'Альпинист', 'Скручивания', 'Ягодичный мост', 'Боковая планка', 'Подтягивания',
    'Махи гирей', 'Бег на месте', 'Велосипед', 'Джампинг-джек',
  ];
  static const _workEn = [
    'Burpees', 'Squats', 'Push-ups', 'Plank', 'Lunges', 'Jump rope', 'Jumping in place',
    'Mountain climbers', 'Crunches', 'Glute bridge', 'Side plank', 'Pull-ups',
    'Kettlebell swings', 'Running in place', 'Bicycle', 'Jumping jacks',
  ];
}

class WorkoutTemplate {
  final String title;
  final String Function(S s) info;
  final Workout Function(S s) build;

  const WorkoutTemplate({required this.title, required this.info, required this.build});

  static Workout simple(S s, String name, {required int work, required int rest, required int rounds}) {
    return Workout.create(name: name, blocks: [
      WorkBlock.create(name: name, repeats: rounds, intervals: [
        WorkInterval.create(name: s.work, seconds: work, type: IntervalType.work),
        if (rest > 0) WorkInterval.create(name: s.rest, seconds: rest, type: IntervalType.rest),
      ]),
    ]);
  }

  static final all = <WorkoutTemplate>[
    WorkoutTemplate(
      title: 'Tabata',
      info: (s) => '20/10 × 8\n${s.minutes(4)}',
      build: (s) => simple(s, 'Tabata', work: 20, rest: 10, rounds: 8),
    ),
    WorkoutTemplate(
      title: 'EMOM',
      info: (s) => '1:00 × 10\n${s.minutes(10)}',
      build: (s) => Workout.create(name: 'EMOM', blocks: [
        WorkBlock.create(name: 'EMOM', repeats: 10, intervals: [
          WorkInterval.create(name: s.ru ? 'Минута' : 'Minute', seconds: 60, type: IntervalType.work),
        ]),
      ]),
    ),
    WorkoutTemplate(
      title: 'AMRAP',
      info: (s) => '${s.continuous}\n${s.minutes(12)}',
      build: (s) => Workout.create(name: 'AMRAP', blocks: [
        WorkBlock.create(name: 'AMRAP', intervals: [
          WorkInterval.create(name: 'AMRAP', seconds: 12 * 60, type: IntervalType.work),
        ]),
      ]),
    ),
    WorkoutTemplate(
      title: 'HIIT',
      info: (s) => '45/15 × 10\n${s.minutes(10)}',
      build: (s) => simple(s, 'HIIT', work: 45, rest: 15, rounds: 10),
    ),
  ];
}
