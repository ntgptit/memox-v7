import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/foundations/app_colors.dart';

/// Logical size the web build is constrained to.
///
/// Roughly a Pixel 7/8 in logical pixels. Web is the E2E and visual-regression
/// channel, not a production target (AD-04), so an unconstrained browser window
/// would produce screenshots that look nothing like the Android build and
/// exercise layout paths Android never takes.
const Size kMobileFrameSize = Size(393, 852);

/// Constrains the app to a phone-sized surface, centred, on the web build.
///
/// Install it through `MaterialApp.builder` rather than around `MaterialApp`:
/// `WidgetsApp` establishes its own `MediaQuery` from the view at its root, so
/// an override placed above it is discarded. Inside `builder` the override sits
/// below that and every route sees it.
///
/// The `MediaQuery` override is the part that matters. A bare `SizedBox` would
/// paint at phone size while `MediaQuery.sizeOf(context)` still reported the
/// browser window — responsive code would then branch as if it were on a
/// desktop while visibly rendering on a phone, which is worse than not framing
/// at all.
class MobileFrameWidget extends StatelessWidget {
  const MobileFrameWidget({
    required this.child,
    this.isEnabled = kIsWeb,
    super.key,
  });

  final Widget child;

  /// Defaults to `kIsWeb`. Exposed so tests can drive both paths — `kIsWeb` is
  /// a compile-time constant and is always false under `flutter test`.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Window already at or below phone size — nothing to frame, and forcing
        // the box here would overflow instead of shrinking.
        final hasRoomToFrame =
            constraints.maxWidth > kMobileFrameSize.width &&
            constraints.maxHeight > kMobileFrameSize.height;
        if (!hasRoomToFrame) return child;

        return ColoredBox(
          // Backdrop outside the app surface. Visible only on the web dev
          // channel, so it is deliberately not a design token — it is not part
          // of the product UI.
          color: AppColors.webLetterbox,
          child: Center(
            child: SizedBox(
              width: kMobileFrameSize.width,
              height: kMobileFrameSize.height,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: kMobileFrameSize,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: ClipRect(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
