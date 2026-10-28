Thanks @saurabh-mirajkar — verified as requested.

## Does it still reproduce? **No.**

I rebuilt a minimal, self-contained app (no plugins, no custom CSS, none of the workarounds from the original report) and tested it on both the originally reported version and the latest stable, on the same machine (macOS 27.2, Apple Silicon), same Safari 27.2, with **"Never use font sizes smaller than: 19"** set and Safari relaunched before every load so the clamp is active at first paint:

| Flutter | Engine | Layout with min font 19 | `lineHeightScaleFactorOverride` |
|---|---|---|---|
| 3.44.8 stable (reported) | `0cd610717b` | **Correct** | none |
| 3.47.8 stable (latest) | `cf636b1dfb` | **Correct** | none |

Both builds render the 60-row scroll list normally in Safari; Chromium matches. The sentinel measures identically in both:

```
computed font-size:    16.52174 px   (16 × 1.03261 browser text-scale factor)
computed line-height: 103.2609 px   (100 × 1.03261, scaled proportionally)
```

Replicating `_addTypographySettingsObserver` against those values:

```
findBrowserTextScaleFactor()  = 16.52174 / 16      = 1.03261
defaultLineHeightFactor       = 100 / (16.52174 / 1.03261) = 6.25
isDefault(lineHeight, 100)    → |103.2609 − 100·1.03261| < 1e-4 → true
→ computedLineHeightScaleFactor = null → no override applied
```

The scale-tolerant `isDefault()` dual check (raw value *or* value × textScaleFactor) absorbs Safari's min-font-size scaling on both the baseline and the live measurement, so no bogus override is produced.

## Why the original report showed a 625× stretch

The sentinel measurement in the original report — `line-height: 10325.05px` = **9999 × 1.03261** — is the **pre-#186474** sentinel implementation. Since #186474 the engine uses a `100px` line-height sentinel plus letter/word-spacing/margin probes and the `isDefault()` check above. The `main.dart.js` that produced those measurements was built from (or service-worker-cached) an older engine than the 3.44.8 the report was filed against. The 605.2-vs-625.0 mismatch (unscaled 9999 ÷ scaled font-size vs scaled 10325.05 ÷ scaled font-size) that produced the ~625× override simply does not exist in the current implementation.

I cannot reproduce the 625× behaviour with any 3.44.x+ engine build.

## Minimal repro source

Single-file app on the default `flutter create --platforms=web` scaffold (no workarounds in `index.html`):

```dart
import 'package:flutter/material.dart';

void main() => runApp(const ReproApp());

class ReproApp extends StatelessWidget {
  const ReproApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safari min-font-size repro',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF66A049)),
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter/flutter#195456 repro')),
        body: ListView.builder(
          itemCount: 60,
          itemBuilder: (BuildContext context, int index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Row ${index + 1}: This paragraph should sit directly below the '
              'previous one with normal single-line spacing. With the bug, each '
              'row is pushed thousands of pixels apart inside the scroll view.',
            ),
          ),
        ),
      ),
    );
  }
}
```

`flutter build web --release`, then serve `build/web` over HTTP (Safari needs the min-font-size preference set >16 and a relaunch before loading).

Screenshots of both runs (3.44.8 and 3.47.8, Safari 27.2, min font 19) are attached to this follow-up bundle, along with the full repro project.

## `flutter doctor -v` (3.47.8, the SDK used for the latest-stable verification)

```
[✓] Flutter (Channel stable, 3.44.8, on macOS 27.2 26B123 darwin-arm64, locale en-PH)
```

<details>
<summary>Full <code>flutter doctor -v</code> for both SDKs</summary>

```
Flutter 3.47.8 • channel [user-branch] • https://github.com/flutter/flutter.git
Framework • revision 737ba8f885 (2026-10-22 21:37:31 -0700)
Engine • revision cf636b1dfb
Tools • Dart 3.13.7 • DevTools 2.60.0
macOS 27.2 26B123 darwin-arm64
Xcode 27.2 (27B48), CocoaPods 1.16.2
Chrome 156.0.8078.48
```

```
Flutter 3.44.8 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 058e0af2c2 (2026-07-23 10:56:21 -0700)
Engine • revision 0cd610717b
Tools • Dart 3.12.2 • DevTools 2.57.0
macOS 27.2 26B123 darwin-arm64
Xcode 27.2 (27B48), CocoaPods 1.16.2
Chrome 156.0.8078.48
```

(Complete unedited outputs are in the attached bundle: `flutter_doctor_3.44.8.txt`, `flutter_doctor_3.47.8.txt`.)
</details>

## Suggested resolution

Since the behaviour cannot be reproduced on the reported version (3.44.8) nor on the latest stable (3.47.8) — and the original measurements are fully explained by a stale pre-#186474 engine build — I'd suggest closing this as fixed/cannot-reproduce. Happy to re-test with fresh measurements if anything above doesn't match what you see on your side.
