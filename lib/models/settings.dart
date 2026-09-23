enum ThemeChoice { light, dark, system }

enum LanguageChoice { system, ru, en }

class AppSettings {
  final bool sound;
  final bool duckMusic;
  final bool haptics;
  final bool keepAwake;
  final bool halfwayCue;
  final bool backgroundCues;

  /// The system notification prompt has been shown once already.
  final bool notificationsAsked;
  final int prepSeconds;
  final ThemeChoice theme;
  final LanguageChoice language;

  /// Last values used on the quick start card.
  final int quickWork;
  final int quickRest;
  final int quickRounds;

  const AppSettings({
    this.sound = true,
    this.duckMusic = false,
    this.haptics = true,
    this.keepAwake = true,
    this.halfwayCue = true,
    this.backgroundCues = true,
    this.notificationsAsked = false,
    this.prepSeconds = 10,
    this.theme = ThemeChoice.light,
    this.language = LanguageChoice.system,
    this.quickWork = 40,
    this.quickRest = 20,
    this.quickRounds = 8,
  });

  AppSettings copyWith({
    bool? sound,
    bool? duckMusic,
    bool? haptics,
    bool? keepAwake,
    bool? halfwayCue,
    bool? backgroundCues,
    bool? notificationsAsked,
    int? prepSeconds,
    ThemeChoice? theme,
    LanguageChoice? language,
    int? quickWork,
    int? quickRest,
    int? quickRounds,
  }) {
    return AppSettings(
      sound: sound ?? this.sound,
      duckMusic: duckMusic ?? this.duckMusic,
      haptics: haptics ?? this.haptics,
      keepAwake: keepAwake ?? this.keepAwake,
      halfwayCue: halfwayCue ?? this.halfwayCue,
      backgroundCues: backgroundCues ?? this.backgroundCues,
      notificationsAsked: notificationsAsked ?? this.notificationsAsked,
      prepSeconds: prepSeconds ?? this.prepSeconds,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      quickWork: quickWork ?? this.quickWork,
      quickRest: quickRest ?? this.quickRest,
      quickRounds: quickRounds ?? this.quickRounds,
    );
  }

  Map<String, dynamic> toJson() => {
        'sound': sound,
        'duckMusic': duckMusic,
        'haptics': haptics,
        'keepAwake': keepAwake,
        'halfwayCue': halfwayCue,
        'backgroundCues': backgroundCues,
        'notificationsAsked': notificationsAsked,
        'prepSeconds': prepSeconds,
        'theme': theme.name,
        'language': language.name,
        'quickWork': quickWork,
        'quickRest': quickRest,
        'quickRounds': quickRounds,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const d = AppSettings();
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    return AppSettings(
      sound: json['sound'] as bool? ?? d.sound,
      duckMusic: json['duckMusic'] as bool? ?? d.duckMusic,
      haptics: json['haptics'] as bool? ?? d.haptics,
      keepAwake: json['keepAwake'] as bool? ?? d.keepAwake,
      halfwayCue: json['halfwayCue'] as bool? ?? d.halfwayCue,
      backgroundCues: json['backgroundCues'] as bool? ?? d.backgroundCues,
      notificationsAsked: json['notificationsAsked'] as bool? ?? d.notificationsAsked,
      prepSeconds: (json['prepSeconds'] as num?)?.toInt() ?? d.prepSeconds,
      theme: pick(ThemeChoice.values, json['theme'], d.theme),
      language: pick(LanguageChoice.values, json['language'], d.language),
      quickWork: (json['quickWork'] as num?)?.toInt() ?? d.quickWork,
      quickRest: (json['quickRest'] as num?)?.toInt() ?? d.quickRest,
      quickRounds: (json['quickRounds'] as num?)?.toInt() ?? d.quickRounds,
    );
  }
}

class HistoryEntry {
  final String workoutName;
  final DateTime startedAt;
  final int elapsedSeconds;
  final int workSeconds;
  final int restSeconds;
  final int intervalsDone;
  final int intervalsTotal;
  final bool completed;

  const HistoryEntry({
    required this.workoutName,
    required this.startedAt,
    required this.elapsedSeconds,
    required this.workSeconds,
    required this.restSeconds,
    required this.intervalsDone,
    required this.intervalsTotal,
    required this.completed,
  });

  HistoryEntry copyWith({String? workoutName}) => HistoryEntry(
        workoutName: workoutName ?? this.workoutName,
        startedAt: startedAt,
        elapsedSeconds: elapsedSeconds,
        workSeconds: workSeconds,
        restSeconds: restSeconds,
        intervalsDone: intervalsDone,
        intervalsTotal: intervalsTotal,
        completed: completed,
      );

  Map<String, dynamic> toJson() => {
        'workoutName': workoutName,
        'startedAt': startedAt.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'workSeconds': workSeconds,
        'restSeconds': restSeconds,
        'intervalsDone': intervalsDone,
        'intervalsTotal': intervalsTotal,
        'completed': completed,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        workoutName: json['workoutName'] as String? ?? '',
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
        elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
        workSeconds: (json['workSeconds'] as num?)?.toInt() ?? 0,
        restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 0,
        intervalsDone: (json['intervalsDone'] as num?)?.toInt() ?? 0,
        intervalsTotal: (json['intervalsTotal'] as num?)?.toInt() ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}
