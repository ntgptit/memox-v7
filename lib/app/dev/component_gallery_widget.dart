import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'component_control_sections_widget.dart';
import 'component_form_sections_widget.dart';
import 'component_state_sections_widget.dart';

/// The Components tab: every `Mx*` component, in every state it can be caught
/// in — enabled, disabled, loading, error, selected — under whichever theme
/// and text scale the showcase toolbar currently applies.
///
/// Demos are rendered **inline**, not through `showDialog` /
/// `showModalBottomSheet`. A popped route builds under the app's root theme,
/// which would silently ignore the showcase's light/dark toggle — the one
/// control this screen exists to provide. The cost is that the action sheet
/// needs a stand-in `Material` surface, because `MxActionSheet` paints none of
/// its own by design.
class ComponentGalleryWidget extends StatelessWidget {
  const ComponentGalleryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const <Widget>[
        ComponentControlSectionsWidget(),
        ComponentFormSectionsWidget(),
        ComponentStateSectionsWidget(),
      ],
    );
  }
}
