import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context_extension.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_page.dart';

void _noop() {}

WidgetbookComponent textFieldComponent() {
  return WidgetbookComponent(
    name: 'MxTextField',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: 'Deck name',
          );
          final hintText = context.knobs.stringOrNull(
            label: 'hintText',
            initialValue: 'e.g. Academic Word List',
          );
          final helperText = context.knobs.stringOrNull(label: 'helperText');
          final errorText = context.knobs.stringOrNull(label: 'errorText');
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final isReadOnly = context.knobs.boolean(label: 'readOnly');
          final maxLength = context.knobs.intOrNull.slider(
            label: 'maxLength',
            min: 10,
            max: 200,
          );

          return CatalogCenterPage(
            child: _TextFieldDemo(
              label: label,
              hintText: hintText,
              helperText: helperText,
              errorText: errorText,
              isEnabled: isEnabled,
              isReadOnly: isReadOnly,
              maxLength: maxLength,
            ),
          );
        },
      ),
    ],
  );
}

/// Owns the controller so it survives knob-driven rebuilds — a controller
/// created inside the use-case builder would be recreated (and leaked) on
/// every knob change.
class _TextFieldDemo extends StatefulWidget {
  const _TextFieldDemo({
    required this.label,
    required this.hintText,
    required this.helperText,
    required this.errorText,
    required this.isEnabled,
    required this.isReadOnly,
    required this.maxLength,
  });

  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isEnabled;
  final bool isReadOnly;
  final int? maxLength;

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MxTextField(
      controller: _controller,
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      isEnabled: widget.isEnabled,
      isReadOnly: widget.isReadOnly,
      maxLength: widget.maxLength,
    );
  }
}

WidgetbookComponent cardComponent() {
  return WidgetbookComponent(
    name: 'MxCard',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final content = context.knobs.string(
            label: 'content',
            initialValue:
                'The app’s one raised surface: bordered, unshadowed, '
                'radius lg.',
            maxLines: 3,
          );

          return CatalogCenterPage(
            child: MxCard(
              child: Text(content, style: context.texts.bodyMedium),
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent listTileComponent() {
  return WidgetbookComponent(
    name: 'MxListTile',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Academic Word List',
          );
          final subtitle = context.knobs.stringOrNull(
            label: 'subtitle',
            initialValue: '120 cards · 8 due',
          );
          final hasLeading = context.knobs.boolean(
            label: 'with leading icon',
            initialValue: true,
          );
          final hasTrailing = context.knobs.boolean(
            label: 'with trailing chevron',
            initialValue: true,
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final isSelected = context.knobs.boolean(label: 'selected');

          return Scaffold(
            body: SafeArea(
              child: Center(
                child: MxListTile(
                  title: title,
                  subtitle: subtitle,
                  leading: hasLeading
                      ? const Icon(Icons.folder_outlined)
                      : null,
                  trailing: hasTrailing
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: _noop,
                  isEnabled: isEnabled,
                  isSelected: isSelected,
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
