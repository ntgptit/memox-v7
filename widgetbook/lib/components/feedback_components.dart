import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
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
