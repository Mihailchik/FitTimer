# HELP / Troubleshooting

## Quick start

```bash
flutter pub get
cd ios && LANG=en_US.UTF-8 pod install && cd ..
flutter devices
flutter run -d <device-id>
```

In Xcode 27 the simulator window lives in **DeviceHub** (`Xcode.app/Contents/Applications/DeviceHub.app`); there is no separate Simulator.app any more.

## Known problems

### `pod install` fails with `Unicode Normalization not appropriate for ASCII-8BIT`
CocoaPods needs a UTF‑8 locale. Run it as `LANG=en_US.UTF-8 pod install` or add `export LANG=en_US.UTF-8` to `~/.zshrc`.

### `You have not agreed to the Xcode license agreements`
Once per Xcode install: `sudo xcodebuild -license accept`.

### `flutter build ios --simulator` fails: `Flutter.framework ... does not contain architectures "arm64 x86_64"`
The generic simulator build asks for Intel slices that current Flutter no longer ships. Build for a concrete simulator instead: `flutter run -d <simulator-id>`.

### Xcode error `'...Plugin' has different definitions in different modules`
Stale module cache after a plugin version change:
```bash
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
flutter pub get && cd ios && LANG=en_US.UTF-8 pod install
```

### No sound when the screen is locked
Background cues are notifications: check that notifications are allowed for FitTimer in iOS Settings and that "Cues when locked" is on in the app. Notification sounds follow the ring/silent switch.

### Text looks jagged in the simulator window
The simulator is shown scaled down, especially on non‑Retina monitors. Zoom the window in, move it to a Retina screen or take a screenshot (`xcrun simctl io booted screenshot shot.png`) to judge real rendering.

## Regenerating assets

- App icon: replace `assets/icon/app_icon.png` (1024×1024, no transparency) and run `dart run flutter_launcher_icons`.
- Launch screen colours: `flutter_native_splash` section in `pubspec.yaml`, then `dart run flutter_native_splash:create`.
- Background cue sounds: `dart run tool/gen_notification_sounds.dart`.
