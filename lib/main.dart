import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_state.dart';
import 'l10n/strings.dart';
import 'models/settings.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceLocale = PlatformDispatcher.instance.locale;
  final state = await AppState.load(
    migratedName: S.forLocale(deviceLocale).ru ? 'Моя тренировка' : 'My workout',
  );
  runApp(FitTimerApp(state: state));
}

class FitTimerApp extends StatelessWidget {
  const FitTimerApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final st = state.settings;
          return MaterialApp(
            title: 'FitTimer',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: switch (st.theme) {
              ThemeChoice.light => ThemeMode.light,
              ThemeChoice.dark => ThemeMode.dark,
              ThemeChoice.system => ThemeMode.system,
            },
            locale: switch (st.language) {
              LanguageChoice.system => null,
              LanguageChoice.ru => const Locale('ru'),
              LanguageChoice.en => const Locale('en'),
            },
            supportedLocales: const [Locale('en'), Locale('ru')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            // Large accessibility text sizes are honoured up to a point where
            // the timer layouts still fit on the smallest supported iPhone.
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.35,
              child: child!,
            ),
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
