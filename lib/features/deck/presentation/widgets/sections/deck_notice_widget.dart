import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';

/// A short banner explaining why an action is not available in this build.
///
/// Used for the card handoff to M4.11. It is a statement, not a control: an
/// enabled-looking button that does nothing is worse than no button, and hiding
/// the fact entirely would leave an `unset` deck looking as though it could only
/// ever hold decks — which contradicts BR-61.
///
/// **It carries no horizontal gutter of its own**: it is a band inside a list
/// that already owns one, and restating it put the notice's icon 16dp inside
/// the card edges it sits between. A caller that mounts it outside a gutter has
/// to supply one.
class DeckNoticeWidget extends StatelessWidget {
  const DeckNoticeWidget({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const MxIcon(
            Icons.info_outline,
            ink: AppInk.info,
            size: MxIconSize.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall!.inked(context, AppInk.quiet),
            ),
          ),
        ],
      ),
    );
  }
}
