import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import '../models/workout.dart';

/// Everything the app keeps on the device: workouts, settings, history.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);

  static const _kWorkouts = 'v2_workouts';
  static const _kSettings = 'v2_settings';
  static const _kHistory = 'v2_history';
  static const _kV1Sequence = 'timer_sequence_v1';
  static const _kV1Muted = 'timer_muted';
  static const historyLimit = 200;

  final SharedPreferences _prefs;

  List<Workout> _workouts = [];
  AppSettings _settings = const AppSettings();
  List<HistoryEntry> _history = [];

  List<Workout> get workouts => List.unmodifiable(_workouts);
  AppSettings get settings => _settings;
  List<HistoryEntry> get history => List.unmodifiable(_history);

  static Future<AppState> load({String migratedName = 'My workout'}) async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState._(prefs);
    state._read(migratedName);
    return state;
  }

  void _read(String migratedName) {
    final settingsRaw = _prefs.getString(_kSettings);
    if (settingsRaw != null) {
      _settings = _safe(() => AppSettings.fromJson(
              jsonDecode(settingsRaw) as Map<String, dynamic>)) ??
          const AppSettings();
    }

    final workoutsRaw = _prefs.getString(_kWorkouts);
    if (workoutsRaw != null) {
      _workouts = _safe(() => (jsonDecode(workoutsRaw) as List)
              .map((e) => Workout.fromJson(e as Map<String, dynamic>))
              .toList()) ??
          [];
    } else {
      _migrateFromV1(migratedName);
    }

    final historyRaw = _prefs.getString(_kHistory);
    if (historyRaw != null) {
      _history = _safe(() => (jsonDecode(historyRaw) as List)
              .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList()) ??
          [];
    }
  }

  /// Version 1 kept a single sequence of blocks. Existing users get it back as
  /// their first saved workout so an update never loses what they set up.
  void _migrateFromV1(String name) {
    final muted = _prefs.getBool(_kV1Muted);
    if (muted != null && _prefs.getString(_kSettings) == null) {
      _settings = _settings.copyWith(sound: !muted);
      _writeSettings();
    }
    final raw = _prefs.getString(_kV1Sequence);
    if (raw == null) return;
    final migrated = _safe(() {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final blocks = ((json['blocks'] as List?) ?? const []).map((b) {
        final bj = b as Map<String, dynamic>;
        return WorkBlock.create(
          name: (bj['name'] as String?) ?? '',
          repeats: ((bj['repeats'] as num?)?.toInt() ?? 1).clamp(1, 99),
          intervals: ((bj['items'] as List?) ?? const []).map((i) {
            final ij = i as Map<String, dynamic>;
            return WorkInterval.create(
              name: (ij['name'] as String?) ?? '',
              seconds: (ij['duration'] as num?)?.toInt() ?? 30,
              type: (ij['isPause'] as bool? ?? false)
                  ? IntervalType.rest
                  : IntervalType.work,
            );
          }).toList(),
        );
      }).toList();
      return Workout.create(name: name, blocks: blocks);
    });
    if (migrated != null && !migrated.isEmpty) {
      _workouts = [migrated];
      _writeWorkouts();
    }
  }

  T? _safe<T>(T Function() fn) {
    try {
      return fn();
    } catch (e) {
      debugPrint('AppState read error: $e');
      return null;
    }
  }

  Workout? workoutById(String id) {
    for (final w in _workouts) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Inserts a new workout or replaces the one with the same id.
  void saveWorkout(Workout w) {
    final i = _workouts.indexWhere((x) => x.id == w.id);
    if (i >= 0) {
      _workouts[i] = w;
    } else {
      _workouts.insert(0, w);
    }
    _writeWorkouts();
    notifyListeners();
  }

  void deleteWorkout(String id) {
    _workouts.removeWhere((w) => w.id == id);
    _writeWorkouts();
    notifyListeners();
  }

  void updateSettings(AppSettings s) {
    _settings = s;
    _writeSettings();
    notifyListeners();
  }

  void addHistory(HistoryEntry e) {
    _history.insert(0, e);
    if (_history.length > historyLimit) {
      _history = _history.sublist(0, historyLimit);
    }
    _prefs.setString(
        _kHistory, jsonEncode(_history.map((h) => h.toJson()).toList()));
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    _prefs.remove(_kHistory);
    notifyListeners();
  }

  void updateHistoryEntry(int index, HistoryEntry entry) {
    if (index < 0 || index >= _history.length) return;
    _history[index] = entry;
    _writeHistory();
    notifyListeners();
  }

  void deleteHistoryEntry(int index) {
    if (index < 0 || index >= _history.length) return;
    _history.removeAt(index);
    _writeHistory();
    notifyListeners();
  }

  void _writeHistory() => _prefs.setString(
      _kHistory, jsonEncode(_history.map((h) => h.toJson()).toList()));

  /// Every interval name the user has typed, most used first; offered next to
  /// the built-in presets.
  List<String> usedIntervalNames(IntervalType type) {
    final counts = <String, int>{};
    for (final w in _workouts) {
      for (final b in w.blocks) {
        for (final i in b.intervals) {
          final n = i.name.trim();
          if (i.type == type && n.isNotEmpty) counts[n] = (counts[n] ?? 0) + 1;
        }
      }
    }
    final names = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return names;
  }

  void _writeWorkouts() => _prefs.setString(
      _kWorkouts, jsonEncode(_workouts.map((w) => w.toJson()).toList()));

  void _writeSettings() =>
      _prefs.setString(_kSettings, jsonEncode(_settings.toJson()));
}

/// Makes [AppState] available to the widget tree and rebuilds dependents.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
