import 'package:flutter/material.dart';

void main() => runApp(const ReproApp());

/// Minimal repro for https://github.com/flutter/flutter/issues/195456
///
/// One scrollable column of text. When Safari's "Never use font sizes
/// smaller than" preference is set above 16 *before* load, the engine's
/// typography sentinel is clamped (font-size scaled down to the minimum
/// while line-height is scaled up by the same browser text-scale factor).
/// `defaultLineHeightFactor` then divides the *unscaled* sentinel height
/// (9999px) by the *scaled* font size, the ratio no longer matches the
/// measured `lineHeight / fontSize`, and the engine applies a bogus
/// `lineHeightScaleFactorOverride` (~625) that stretches every paragraph.
///
/// Expected: a normal list of 60 text rows inside a scroll view.
/// Broken:   the first row renders, then rows are pushed thousands of
///           pixels apart (or the page looks blank).
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
