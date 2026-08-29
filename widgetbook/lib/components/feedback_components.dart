import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_feedback_band.dart';
import 'package:memox/shared/widgets/mx_text_button.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_session_top_bar.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_page.dart';

void _noop() {}

WidgetbookComponent emptyStateComponent() {
  return WidgetbookComponent(
    name: 'MxEmptyState',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'All done for today',
          );
          final message = context.knobs.stringOrNull(
            label: 'message',
            initialValue: 'Nothing is due. Come back tomorrow.',
          );
          final actionLabel = context.knobs.stringOrNull(
            label: 'actionLabel',
            initialValue: 'Browse decks',
          );

          return CatalogCenterPage(
            child: MxEmptyState(
              title: title,
              message: message,
              actionLabel: actionLabel,
              onAction: actionLabel == null ? null : _noop,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent feedbackBandComponent() {
  return WidgetbookComponent(
    name: 'MxFeedbackBand',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Could not save',
          );
          final message = context.knobs.string(
            label: 'message',
            initialValue: 'Something went wrong. Your changes are still here.',
          );
          final hasAction = context.knobs.boolean(
            label: 'action',
            initialValue: true,
          );

          return CatalogListPage(
            children: <Widget>[
              MxFeedbackBand(
                title: title,
                message: message,
                action: hasAction
                    ? MxTextButton(
                        label: 'Try again',
                        onPressed: _noop,
                        accent: Theme.of(context).colorScheme.onErrorContainer,
                      )
                    : null,
              ),
            ],
          );
        },
      ),
    ],
  );
}

WidgetbookComponent errorStateComponent() {
  return WidgetbookComponent(
    name: 'MxErrorState',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Something went wrong',
          );
          final message = context.knobs.string(
            label: 'message',
            initialValue: 'Could not load this content.',
          );
          final retryLabel = context.knobs.stringOrNull(
            label: 'retryLabel',
            initialValue: 'Try again',
          );

          return CatalogCenterPage(
            child: MxErrorState(
              title: title,
              message: message,
              retryLabel: retryLabel,
              onRetry: retryLabel == null ? null : _noop,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent loadingStateComponent() {
  return WidgetbookComponent(
    name: 'MxLoadingState',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final semanticsLabel = context.knobs.string(
            label: 'semanticsLabel',
            initialValue: 'Loading decks',
          );

          return CatalogCenterPage(
            child: MxLoadingState(semanticsLabel: semanticsLabel),
          );
        },
      ),
    ],
  );
}

/// The session bar, with no horizontal padding around it on purpose.
///
/// [CatalogCenterPage] would add the screen gutter, and the gutter is the one
/// thing this component must not be given: its close button hangs into it so the
/// ✕ glyph lands *at* the gutter while the trailing figure stops on it. Padded,
/// the catalog would show a bar that is off-centre by exactly the amount the
/// component exists to remove.
WidgetbookComponent sessionTopBarComponent() {
  return WidgetbookComponent(
    name: 'MxSessionTopBar',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: 'Browse',
          );
          final progress = context.knobs.double.slider(
            label: 'progress',
            initialValue: 0.3,
          );
          final trailing = context.knobs.string(
            label: 'trailing',
            initialValue: '3 / 10',
          );

          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  children: <Widget>[
                    MxSessionTopBar(
                      label: label,
                      progress: progress,
                      trailing: Text(trailing),
                      onClose: _noop,
                      closeLabel: 'Close session',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
