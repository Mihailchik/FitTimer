import 'package:flutter/widgets.dart';

import '../models/workout.dart';

/// All user-facing text in Russian and English.
class S {
  final bool ru;
  const S._(this.ru);

  static const _ru = S._(true);
  static const _en = S._(false);

  static S of(BuildContext context) =>
      forLocale(Localizations.localeOf(context));
  static S forLocale(Locale locale) => locale.languageCode == 'ru' ? _ru : _en;

  String _(String ru, String en) => this.ru ? ru : en;

  // Navigation
  String get workouts => _('Тренировки', 'Workouts');
  String get history => _('История', 'History');
  String get settings => _('Настройки', 'Settings');

  // Home
  String get quickStart => _('Быстрый старт', 'Quick start');
  String get total => _('Всего', 'Total');
  String get work => _('Работа', 'Work');
  String get rest => _('Отдых', 'Rest');
  String get prep => _('Подготовка', 'Get ready');
  String get rounds => _('Раунды', 'Rounds');
  String get start => _('Старт', 'Start');
  String get templates => _('Шаблоны', 'Templates');
  String get myWorkouts => _('Мои тренировки', 'My workouts');
  String get newWorkout => _('Новая тренировка', 'New workout');
  String get emptyWorkouts => _(
      'Здесь будут твои тренировки. Создай свою или начни с шаблона.',
      'Your workouts will live here. Create one or start from a template.');
  String get create => _('Создать', 'Create');
  String get edit => _('Изменить', 'Edit');
  String get detailsAndEdit => _('Подробнее и изменить', 'Details and edit');
  String get saveAsMine => _('Сохранить в мои', 'Save to my workouts');
  String addAndEditTemplate(String name) =>
      ru ? 'Добавить и изменить $name' : 'Add and edit $name';
  String get saveAndEdit => _('Сохранить и изменить', 'Save and edit');
  String get continuous => _('Сплошной', 'Continuous');
  String get quickWorkoutName => _('Быстрая тренировка', 'Quick workout');

  // Editor
  String get block => _('Блок', 'Block');
  String get interval => _('Интервал', 'Interval');
  String get addBlock => _('Блок', 'Block');
  String get addInterval => _('Интервал', 'Interval');
  String get rename => _('Переименовать', 'Rename');
  String get duplicate => _('Дублировать', 'Duplicate');
  String get delete => _('Удалить', 'Delete');
  String get moveUp => _('Выше', 'Move up');
  String get moveDown => _('Ниже', 'Move down');
  String get deleteWorkout => _('Удалить тренировку', 'Delete workout');
  String get deleteWorkoutQ => _('Удалить тренировку?', 'Delete this workout?');
  String get cannotUndo => _('Это нельзя отменить.', 'This cannot be undone.');
  String get cancel => _('Отмена', 'Cancel');
  String get done => _('Готово', 'Done');
  String get name => _('Название', 'Name');
  String get workoutName => _('Название тренировки', 'Workout name');
  String get blockName => _('Название блока', 'Block name');
  String get type => _('Тип', 'Type');
  String get minSec => _('мин : сек', 'min : sec');
  String get fewerRepeats => _('Меньше повторов', 'Fewer repeats');
  String get moreRepeats => _('Больше повторов', 'More repeats');
  String get more => _('Ещё', 'More');
  String get back => _('Назад', 'Back');
  String get emptyBlock =>
      _('Добавь первый интервал', 'Add the first interval');
  String get emptyWorkout =>
      _('Добавь блок, чтобы начать', 'Add a block to get started');
  String get suggestions => _('Быстрый выбор', 'Suggestions');

  String blocksCount(int n) => ru
      ? '$n ${_plural(n, 'блок', 'блока', 'блоков')}'
      : '$n ${n == 1 ? 'block' : 'blocks'}';
  String intervalsCount(int n) => ru
      ? '$n ${_plural(n, 'интервал', 'интервала', 'интервалов')}'
      : '$n ${n == 1 ? 'interval' : 'intervals'}';
  String intervalsProgress(int done, int total) =>
      ru ? '$done из $total' : '$done of $total';
  String minutes(int n) => ru ? '$n мин' : '$n min';
  String copyOf(String name) => ru ? '$name (копия)' : '$name (copy)';

  String typeName(IntervalType t) => switch (t) {
        IntervalType.work => work,
        IntervalType.rest => rest,
        IntervalType.prep => prep,
      };

  // Run
  String get getReady => _('Приготовься', 'Get ready');
  String get upNext => _('Дальше', 'Next');
  String get finishLine => _('Финиш', 'Finish');
  String get elapsed => _('Прошло', 'Elapsed');
  String get remaining => _('Осталось', 'Left');
  String get paused => _('Пауза', 'Paused');
  String get resume => _('Продолжить', 'Resume');
  String get restartInterval => _('Заново', 'Restart');
  String get endWorkout => _('Завершить', 'End workout');
  String get pause => _('Пауза', 'Pause');
  String get previous => _('Предыдущий интервал', 'Previous interval');
  String get nextInterval => _('Следующий интервал', 'Next interval');
  String get close => _('Закрыть', 'Close');
  String get soundOn => _('Звук включён', 'Sound on');
  String get soundOff => _('Звук выключен', 'Sound off');
  String roundOf(int r, int n) => ru ? 'Раунд $r из $n' : 'Round $r of $n';
  String nowDoing(String name) => ru ? 'Сейчас: $name' : 'Up: $name';

  // Finish
  String get wellDone => _('Готово!', 'Done!');
  String get stoppedEarly => _('Тренировка остановлена', 'Workout stopped');
  String get time => _('Время', 'Time');
  String get intervals => _('Интервалы', 'Intervals');
  String get repeat => _('Повторить', 'Repeat');

  // History
  String get emptyHistory => _(
      'Пока пусто. Заверши тренировку — она появится здесь.',
      'Nothing yet. Finish a workout and it shows up here.');
  String get today => _('Сегодня', 'Today');
  String get yesterday => _('Вчера', 'Yesterday');
  String get clearHistory => _('Очистить историю', 'Clear history');
  String get deleteHistoryEntry => _('Удалить запись', 'Delete entry');
  String get deleteHistoryEntryQ =>
      _('Удалить эту запись?', 'Delete this entry?');
  String get historyDetails => _('Итоги тренировки', 'Workout details');

  // Settings
  String get soundAndHaptics => _('Звук и вибрация', 'Sound & haptics');
  String get sounds => _('Звуковые сигналы', 'Sound cues');
  String get duckMusic => _('Приглушать музыку', 'Lower music');
  String get duckMusicHint => _('Музыка тише, пока идёт тренировка',
      'Music plays quieter during a workout');
  String get vibration => _('Вибрация', 'Vibration');
  String get training => _('Тренировка', 'Workout');
  String get prepBeforeStart =>
      _('Подготовка перед стартом', 'Get-ready countdown');
  String get keepAwake => _('Не гасить экран', 'Keep screen on');
  String get halfwayCue => _('Сигнал на середине', 'Halfway signal');
  String get halfwayCueHint =>
      _('Для работы длиннее 30 секунд', 'For work longer than 30 seconds');
  String get general => _('Общие', 'General');
  String get language => _('Язык', 'Language');
  String get theme => _('Тема', 'Theme');
  String get themeLight => _('Светлая', 'Light');
  String get themeDark => _('Тёмная', 'Dark');
  String get themeSystem => _('Как в системе', 'System');
  String get langSystem => _('Как в системе', 'System');
  String get off => _('Выкл', 'Off');
  String get version => _('Версия', 'Version');

  static String _plural(int n, String one, String few, String many) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return one;
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
    return many;
  }
}

/// 75 -> "1:15", 5 -> "0:05", 3725 -> "1:02:05".
String formatClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final ss = sec.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}
