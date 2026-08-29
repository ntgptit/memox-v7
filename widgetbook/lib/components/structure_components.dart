import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/shared/widgets/mx_async_view.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_sheet_insets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_page.dart';

/// The components that decide how a *page* reads, rather than how a control does.
///
/// **Added at M100.6, and the gap they were in is the point.** The kit's Widgetbook
/// coverage was measured widget by widget and came back missing eight entries —
/// led by `MxContentShell`, which 23 files use 31 times and which owns every
/// screen's title, bar and padding. A catalogue that shows every button and no
/// page frame answers "what does a button look like" and cannot answer "why do
/// these two screens have different gutters", which is the question the frame
/// exists to settle.
///
/// `MxSheetInsets` is here for the same reason even though it paints nothing of
/// its own: its whole job is a measurement, and a measurement with no picture is
/// the kind of thing two screens quietly disagree about.

void _noop() {}

void _noopString(String value) {}

/// The page frame: title, optional subline, actions, and the body it wraps.
WidgetbookComponent contentShellComponent() {
  return WidgetbookComponent(
    name: 'MxContentShell',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Library',
          );
          final subline = context.knobs.stringOrNull(
            label: 'titleSubline',
            initialValue: '3 decks · 868 cards',
          );
          final hasActions = context.knobs.boolean(
            label: 'actions',
            initialValue: true,
          );
          final hasFab = context.knobs.boolean(label: 'fab');
          final isScrollable = context.knobs.boolean(
            label: 'isScrollable',
            initialValue: true,
          );

          return MxContentShell(
            title: title,
            titleSubline: subline == null ? null : Text(subline),
            isScrollable: isScrollable,
            actions: hasActions
                ? const <Widget>[
                    IconButton(onPressed: _noop, icon: Icon(Icons.search)),
                  ]
                : null,
            floatingActionButton: hasFab
                ? const FloatingActionButton(
                    onPressed: _noop,
                    child: Icon(Icons.add),
                  )
                : null,
            body: Column(
              children: <Widget>[
                for (var index = 0; index < 4; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MxCard.raised(child: Text('Body card ${index + 1}')),
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

/// Loading, error and data from one `AsyncValue` — the three faces every screen
/// in this app shows, in the one widget that decides which.
WidgetbookComponent asyncViewComponent() {
  return WidgetbookComponent(
    name: 'MxAsyncView',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final face = context.knobs.object.dropdown<String>(
            label: 'face',
            options: <String>['data', 'loading', 'error'],
          );

          final value = switch (face) {
            'loading' => const AsyncValue<String>.loading(),
            'error' => AsyncValue<String>.error(
              Exception('boom'),
              StackTrace.empty,
            ),
            _ => const AsyncValue<String>.data('868 cards'),
          };

          return CatalogCenterPage(
            child: MxAsyncView<String>(
              value: value,
              loadingLabel: 'Loading the library',
              data: (String value) => Text(value),
              error: (Object error, StackTrace stackTrace) =>
                  const MxErrorState(
                    title: 'Could not load',
                    message: 'Something went wrong reading this deck.',
                  ),
            ),
          );
        },
      ),
    ],
  );
}

/// The bar, at both sizes and both shapes, with and without its two labels.
WidgetbookComponent progressBarComponent() {
  return WidgetbookComponent(
    name: 'MxProgressBar',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final value = context.knobs.double.slider(
            label: 'value',
            initialValue: 0.61,
            max: 1,
          );
          final size = context.knobs.object.dropdown<MxProgressBarSize>(
            label: 'size',
            options: MxProgressBarSize.values,
            labelBuilder: (MxProgressBarSize value) => value.name,
          );
          final shape = context.knobs.object.dropdown<MxProgressBarShape>(
            label: 'shape',
            options: MxProgressBarShape.values,
            labelBuilder: (MxProgressBarShape value) => value.name,
          );
          final label = context.knobs.stringOrNull(
            label: 'label',
            initialValue: 'Learned',
          );
          final valueLabel = context.knobs.stringOrNull(
            label: 'valueLabel',
            initialValue: '61%',
          );

          return CatalogListPage(
            children: <Widget>[
              MxProgressBar(
                value: value,
                size: size,
                shape: shape,
                label: label,
                valueLabel: valueLabel,
              ),
            ],
          );
        },
      ),
    ],
  );
}

/// The search field, including the count badge that only appears once a query
/// has run.
WidgetbookComponent searchFieldComponent() {
  return WidgetbookComponent(
    name: 'MxSearchField',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final value = context.knobs.string(
            label: 'value',
            initialValue: 'noun',
          );
          final hasCount = context.knobs.boolean(
            label: 'resultCount',
            initialValue: true,
          );
          final count = context.knobs.int.slider(
            label: 'count',
            initialValue: 3,
            max: 999,
          );

          return CatalogListPage(
            children: <Widget>[
              MxSearchField(
                value: value,
                onChanged: _noopString,
                hintText: 'Search decks and cards',
                resultCount: hasCount ? count : null,
              ),
            ],
          );
        },
      ),
    ],
  );
}

/// The sheet's own margins, drawn against a tinted child so the measurement is
/// the thing on screen.
WidgetbookComponent sheetInsetsComponent() {
  return WidgetbookComponent(
    name: 'MxSheetInsets',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          return ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: MxSheetInsets(
              child: MxCard.raised(
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Sheet body',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
