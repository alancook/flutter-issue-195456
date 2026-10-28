# Follow-up for flutter/flutter#195456

Verification requested by @saurabh-mirajkar: *"Could you please verify whether
this issue still reproduces on the latest stable Flutter and if it does,
provide a minimal, self-contained code sample that reproduces it?"*

## Answer: no longer reproduces on latest stable (or on the originally reported version)

The issue **does not reproduce** on either:

- **Flutter 3.44.8 stable** (the version originally reported, engine `0cd610717b`)
- **Flutter 3.47.8 stable** (latest stable at time of writing, engine `cf636b1dfb`)

…on the same machine, same Safari, same Safari preference, with a freshly built
minimal app that contains **no workaround CSS** (the `index.html` sentinel rule
from the original report was deliberately removed for this test).

## Test environment

- macOS 27.2 (26B123, darwin-arm64)
- Safari 27.2 (AppleWebKit 605.1.15), `defaults read com.apple.Safari WebKitMinimumFontSize` → **19**
  (set via Settings → Advanced → "Never use font sizes smaller than: 19",
  Safari relaunched before every load so the clamp is active at first paint)
- `flutter build web --release`, default renderer (CanvasKit), served over
  `python3 -m http.server` on localhost

`flutter doctor -v` output for both SDKs is attached
(`flutter_doctor_3.44.8.txt`, `flutter_doctor_3.47.8.txt`).

## Minimal repro

Attached as `safari_minfont_repro.zip` (sources also inlined in this comment):
a raw `flutter create --platforms=web` scaffold whose `main.dart` is a single
`ListView` of 60 `Text` rows — no plugins, no custom CSS, no workarounds.

## Measurements (identical for both Flutter versions)

Reading the sentinel (`<p aria-hidden="true">flutter typography measurement</p>`)
via `getComputedStyle` with min font size 19 active:

```
computed font-size:    16.52174 px   (16 × 1.03261 — Safari's text-scale factor)
computed line-height: 103.2609 px   (100 × 1.03261 — scaled proportionally)
```

Replicating the engine's own math
(`EnginePlatformDispatcher._addTypographySettingsObserver`):

```
findBrowserTextScaleFactor()   = 16.52174 / 16 = 1.03261
defaultLineHeightFactor        = 100 / (16.52174 / 1.03261) = 6.25
isDefault(lineHeight, 100)     → |103.2609 − 100·1.03261| < 0.0001  → true
computedLineHeightScaleFactor  = null            (line-height treated as default)
lineHeightScaleFactorOverride  = null            (no bogus override applied)
```

Layout renders normally: 60 tightly-spaced rows, matching Chromium. Screenshots
from both runs are attached (`flutter_3_44_8_safari27_minfont19.png`,
`flutter_3_47_8_safari27_minfont19.png`).

## Why the original report showed a 625× stretch

The original report measured the sentinel at `font-size: 16.52174px;
line-height: 10325.05px` — a **9999px** sentinel line-height scaled by the
browser text-scale factor (9999 × 1.03261 = 10325.05). A 9999px sentinel
line-height is the **pre-#186474** implementation; since #186474 (included in
the 3.44.x stable line the report was filed against) the sentinel uses
`line-height: 100px` plus letter/word-spacing probes and a scale-tolerant
`isDefault()` check. The `main.dart.js` in the app that produced those
measurements was built from (or service-worker-cached) an older engine.

With the 9999px sentinel, `defaultLineHeightFactor` divided unscaled 9999 by
the scaled font size (9999 / 16.52174 ≈ 605.2) while the measured ratio was
10325.05 / 16.52174 ≈ 625.0 — the mismatch produced the ~625×
`lineHeightScaleFactorOverride`. With the current 100px sentinel, both values
scale identically (100 → 103.26), `isDefault()` matches on the scaled branch,
and no override is applied.

I can no longer reproduce the 625× behaviour with any 3.44.x+ engine build;
if it is still desirable to defend against a UA/user-stylesheet forcing a
small font-size on the sentinel, the current `isDefault()` dual-check
(raw value or value × textScaleFactor) already covers the min-font-size case.

## Requested resolution

Since the behaviour cannot be reproduced on the reported version (3.44.8) nor
on the latest stable (3.47.8), I believe this issue can be closed as
`fixed`/`cannot-reproduce` (the residual symptom in the original report is
fully explained by a stale pre-#186474 engine build). Happy to re-open with
fresh measurements if any of the above doesn't match what you see on your side.
