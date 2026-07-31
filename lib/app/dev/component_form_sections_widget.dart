import 'package:flutter/material.dart';

import '../../core/theme/theme_context_extension.dart';
import '../../shared/widgets/mx_card.dart';
import '../../shared/widgets/mx_list_tile.dart';
import '../../shared/widgets/mx_text_field.dart';
import 'showcase_section_widget.dart';

/// The form and content demos of the component gallery: `MxTextField` in its
/// four states, `MxCard`, and `MxListTile` in its four row shapes.
///
/// Stateful only because `MxTextField` requires a controller and a controller
/// must be disposed; nothing here holds state a rebuild could lose.
class ComponentFormSectionsWidget extends StatefulWidget {
  const ComponentFormSectionsWidget({super.key});

  @override
  State<ComponentFormSectionsWidget> createState() =>
      _ComponentFormSectionsWidgetState();
}

/// Demo character limit for the counter text field.
const int _demoMaxLength = 40;

void _noop() {}

class _ComponentFormSectionsWidgetState
    extends State<ComponentFormSectionsWidget> {
  final TextEditingController _plainController = TextEditingController();
  final TextEditingController _errorController = TextEditingController(
    text: 'Duplicate name',
  );
  final TextEditingController _disabledController = TextEditingController(
    text: 'Not editable',
  );
  final TextEditingController _countedController = TextEditingController(
    text: 'Counts toward a limit',
  );

  @override
  void dispose() {
    _plainController.dispose();
    _errorController.dispose();
    _disabledController.dispose();
    _countedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTextFieldSection(),
        const _CardSection(),
        const _ListTileSection(),
      ],
    );
  }

  /// A method rather than a class because the demos read the state's
  /// controllers; the section renders nothing that outlives them.
  Widget _buildTextFieldSection() {
    return ShowcaseSectionWidget(
      title: 'MxTextField',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'default · with helper',
          child: MxTextField(
            controller: _plainController,
            label: 'Deck name',
            hintText: 'e.g. Academic Word List',
            helperText: 'Shown under the field while nothing is wrong',
          ),
        ),
        ShowcaseItemWidget(
          label: 'error',
          child: MxTextField(
            controller: _errorController,
            label: 'Deck name',
            errorText: 'A deck with this name already exists (demo)',
          ),
        ),
        ShowcaseItemWidget(
          label: 'disabled',
          child: MxTextField(
            controller: _disabledController,
            label: 'Deck name',
            isEnabled: false,
          ),
        ),
        ShowcaseItemWidget(
          label: 'with maxLength counter',
          child: MxTextField(
            controller: _countedController,
            label: 'Note',
            maxLength: _demoMaxLength,
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection();

  @override
  Widget build(BuildContext context) {
    return ShowcaseSectionWidget(
      title: 'MxCard',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'default',
          child: MxCard(
            child: Text(
              'The app’s one raised surface: bordered, unshadowed, radius lg.',
              style: context.texts.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _ListTileSection extends StatelessWidget {
  const _ListTileSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'MxListTile',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'default / two-line / selected / disabled',
          // Bare on the scaffold background, exactly as list rows sit in the
          // product. A surface wrapper here (an `MxCard`) trips the
          // framework's Material assertion — `ListTile` paints splashes on
          // the nearest `Material`, not on a `DecoratedBox`.
          child: Column(
            children: <Widget>[
              MxListTile(title: 'Title only', onTap: _noop),
              MxListTile(
                title: 'With subtitle and affordances',
                subtitle: 'Leading icon, trailing chevron',
                leading: Icon(Icons.folder_outlined),
                trailing: Icon(Icons.chevron_right),
                onTap: _noop,
              ),
              MxListTile(title: 'Selected', onTap: _noop, isSelected: true),
              MxListTile(title: 'Disabled', isEnabled: false),
            ],
          ),
        ),
      ],
    );
  }
}
