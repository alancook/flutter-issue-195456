# safari_minfont_repro

Minimal, self-contained repro for [flutter/flutter#195456](https://github.com/flutter/flutter/issues/195456):
Safari 27 + minimum font size > 16 and the Flutter web typography sentinel.

## Contents

```
pubspec.yaml      # single dependency: Flutter SDK
lib/main.dart     # 60-row scrollable text list (all that is needed)
web/index.html    # default scaffold index (no workarounds applied)
```

No plugins, no fonts, no Firebase, no custom CSS — the raw `flutter create`
web scaffold plus one `ListView` of `Text` rows.

## How to build

```bash
flutter pub get
flutter build web --release
cd build/web && python3 -m http.server 8123
```

## How to reproduce

1. In Safari, set **Settings → Advanced → "Never use font sizes smaller than"**
   to a value **greater than 16** (e.g. 19), then quit and relaunch Safari so
   the preference is in force *before* the page loads.
2. Open the served app URL.
3. Compare with the same URL in Chrome — Chrome shows the correct layout in
   both cases.

## Result summary (measured on the reporter's machine)

| Flutter | Safari min font 19 | Layout | Sentinel (font-size / line-height) |
|---|---|---|---|
| 3.44.8 (reported) | set before load | **Correct** | 16.52174px / 103.2609px |
| 3.47.8 (latest stable) | set before load | **Correct** | 16.52174px / 103.2609px |

Both versions contain the identical post-#186474 sentinel implementation and
apply **no** `lineHeightScaleFactorOverride` on Safari 27.2 with
`WebKitMinimumFontSize = 19`. Details in `FOLLOW_UP.md` (one level up).
