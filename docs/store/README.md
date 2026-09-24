# Store materials

- `listing.md` — App Store texts (RU/EN) with length limits checked.
- `screenshots/iphone_6.9/{ru,en}/` — 6 screenshots each, 1320×2868 (iPhone 6.9" size bucket): home, work phase, rest phase, editor, interval sheet, history. Captured on the "Store iPhone 6.9" simulator (iPhone 17 Pro Max) with seeded demo data.
- `screenshots/ipad_13/ru/` — 5 screenshots, 2064×2752 (iPad 13" size bucket): home, work phase, rest phase, editor, interval sheet. English set not captured — RU set covers the required minimum (Apple requires at least one iPad size class if the app supports iPad, one language is enough).
- v1 screenshots are archived in `../v1/` for reference only (some include Flutter's DEBUG banner).

## Uploading

App Store Connect → App Store → [version] → scroll to the size bucket → drag the 6 (or 5) files in order. iPhone 6.9" screenshots also satisfy the 6.5" requirement (Apple accepts the same image). No 5.5" screenshots exist — not required unless the app still targets very old devices; this app's minimum is iOS 15 so 5.5" is not applicable.
