# FitTimer

Interval training timer for iPhone and iPad — Tabata, HIIT, EMOM, AMRAP and your own circuits.
[App Store](https://apps.apple.com/app/id6755115543) · [Privacy Policy](docs/legal/PRIVACY_POLICY.md) · [Terms](docs/legal/TERMS_OF_USE.md) · [Changelog](CHANGELOG.md)

[Русская версия ниже](#fittimer--интервальный-таймер)

## Features

- **Quick start** — set work, rest and rounds on three wheels and go.
- **Templates** — Tabata, EMOM, AMRAP, HIIT: start as is or save and edit.
- **Your workouts** — blocks with repeats, intervals of type work / rest / get ready, drag to reorder, ready-made exercise names.
- **Workout screen** — the screen takes the phase colour (bright in the light theme, deep tint in the dark one), big digits, progress ring, "next up", skip and pause.
- **Cues** — 3‑2‑1 countdown, start and halfway signals, vibration; plays over your music.
- **Screen locked? Still audible** — interval changes arrive as sound notifications while the app is in the background.
- **Exact time** — counted from the clock, not from ticks, so it stays right after pauses and switching apps.
- **History**, light and dark theme, Russian and English.
- No account, no ads, no tracking. Data stays on the device.

## Build

Requirements: Flutter 3.44+, Xcode 27+, CocoaPods, iOS 15+ device or simulator.

```bash
flutter pub get
cd ios && LANG=en_US.UTF-8 pod install && cd ..
flutter run -d <device-id>
```

Tests: `flutter test` (timer engine, v1 data migration, layouts on iPhone SE…iPad with large text, UI details).

Build for the App Store: `flutter build ipa` → upload the `.ipa` with Transporter or Xcode Organizer.

Troubleshooting: see [HELP.md](HELP.md).

## Project layout

```
lib/
  engine/   timer engine (clock-based), timeline, cue sounds, background cues
  models/   workouts, settings, history
  data/     local storage, v1 migration, templates and name presets
  l10n/     Russian and English strings
  ui/       theme, icons, screens and shared widgets
test/       unit and widget tests
tool/       gen_notification_sounds.dart — regenerates ios/Runner/Sounds/*.wav
assets/     app icon source, icon font (Phosphor, MIT)
docs/       legal pages, store texts and screenshots
```

After changing `lib/engine/sounds.dart` run `dart run tool/gen_notification_sounds.dart` so the background cues match.

---

# FitTimer — интервальный таймер

Таймер для интервальных тренировок на iPhone и iPad: Tabata, HIIT, EMOM, AMRAP и собственные круговые тренировки.

## Возможности

- **Быстрый старт** — работа, отдых и раунды на трёх колёсах, и вперёд.
- **Шаблоны** — Tabata, EMOM, AMRAP, HIIT: запустить сразу или сохранить и поправить.
- **Свои тренировки** — блоки с повторами, интервалы типа работа / отдых / подготовка, перетаскивание, готовые названия упражнений.
- **Экран тренировки** — экран в цвете фазы (яркий в светлой теме, глубокий оттенок в тёмной), крупные цифры, кольцо прогресса, «дальше», перемотка и пауза.
- **Сигналы** — отсчёт 3‑2‑1, старт, середина интервала, вибрация; звучат поверх музыки.
- **Экран погас — всё слышно** — смены интервалов приходят уведомлениями со звуком, пока приложение в фоне.
- **Точное время** — считается по часам, а не шагами, поэтому не сбивается после паузы и сворачивания.
- **История**, светлая и тёмная тема, русский и английский.
- Без регистрации, рекламы и слежки. Данные остаются на устройстве.

## Сборка

Нужны Flutter 3.44+, Xcode 27+, CocoaPods, устройство или симулятор с iOS 15+.

```bash
flutter pub get
cd ios && LANG=en_US.UTF-8 pod install && cd ..
flutter run -d <device-id>
```

Тесты — `flutter test`. Сборка для стора — `flutter build ipa`. Решение проблем — [HELP.md](HELP.md).

© 2025–2026 Mihailchik. All rights reserved. See [docs/legal/COPYRIGHT.md](docs/legal/COPYRIGHT.md).
