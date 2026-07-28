import 'package:flutter/material.dart';

import 'mobile_frame_widget.dart';

/// Root widget of the application.
///
/// Deliberately minimal. Each foundation piece arrives in its own task rather
/// than being stubbed here, so nothing has to be un-guessed later:
///
/// * theme and design tokens — M3.4, M3.5
/// * localization, which removes the placeholder strings below — M2.4
/// * routing via `MaterialApp.router` — M4.1
/// * `ProviderScope` and bootstrap wiring — M2.6, M3.3
class MemoxApp extends StatelessWidget {
  const MemoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The two literals below are the only user-visible strings in the project
    // and exist purely so the app renders something before M2.4 introduces ARB.
    // M2.4 must remove them; `CLAUDE.md` forbids user-visible strings outside
    // the ARB files.
    return MaterialApp(
      title: 'memox',
      // Phone-sized surface on web (AD-04). No-op on Android.
      builder: (context, child) =>
          MobileFrameWidget(child: child ?? const SizedBox.shrink()),
      home: const Scaffold(body: Center(child: Text('memox'))),
    );
  }
}
