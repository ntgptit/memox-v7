import 'package:flutter/material.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_session_top_bar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'golden_surfaces.dart';

/// Specimen widgets for the golden suite.
///
/// They live here rather than beside the cases because a specimen is a test
/// fixture, not a test: none of them asserts anything, and keeping them in
/// the same file pushed it past the size the guard allows.
///
/// A specimen is what gets photographed. The stands it sometimes has to sit on
/// — focus, an open route, a highlight strategy — moved to `golden_hosts.dart`
/// when the pill specimen took this file past that guard a second time.
void noop() {}

/// Swallows a destination index.
///
/// A golden is a still frame: the specimen must render the selection it was
/// given, not react to a tap that never happens.
void noopIndex(int index) {}

/// The two destinations the app ships, as the shell builds them.
///
/// Copy is hardcoded English here on purpose: a golden pins pixels, and reading
/// it from ARB would make every future copy edit a golden failure in a file
/// about layout. The real screen takes its labels from ARB — asserted in the
/// router and shell tests.
const List<NavigationDestination> navigationDestinations =
    <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: 'Decks',
      ),
      NavigationDestination(
        icon: Icon(Icons.school_outlined),
        selectedIcon: Icon(Icons.school),
        label: 'Study',
      ),
    ];

/// One line per text role, so a missing family or a stuck weight axis is
/// visible rather than inferred.
class TypographySpecimen extends StatelessWidget {
  const TypographySpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // The card prompt, not `headlineMedium`: this line exists to show
          // the app's largest text, and that is the prompt's own style since
          // it left the scale (`AppTextStyles.cardPrompt`).
          Text('Ephemeral', style: context.textStyles.cardPrompt),
          const SizedBox(height: 12),
          Text('Display / Jakarta 600', style: texts.titleLarge),
          Text('Title / Inter 600', style: texts.titleMedium),
          Text('Body / Inter 400 — 0123456789', style: texts.bodyMedium),
          Text('Label / Inter 600', style: texts.labelLarge),
          Text('Caption / Inter 400', style: texts.bodySmall),
        ],
      ),
    );
  }
}

class CardPrompt extends StatelessWidget {
  const CardPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('ephemeral', style: context.textStyles.cardPrompt),
        const SizedBox(height: 8),
        Text('adjective · /ɪˈfem(ə)rəl/', style: texts.bodyMedium),
      ],
    );
  }
}

/// A field with a controller, so the specimen can be `const` at the call site.
class TextFieldSpecimen extends StatefulWidget {
  const TextFieldSpecimen({
    super.key,
    this.errorText,
    this.isEnabled = true,
    this.shouldAutofocus = false,
  });

  final String? errorText;
  final bool isEnabled;
  final bool shouldAutofocus;

  @override
  State<TextFieldSpecimen> createState() => _TextFieldSpecimenState();
}

class _TextFieldSpecimenState extends State<TextFieldSpecimen> {
  // The selection is placed up front so that taking focus does not also raise
  // the selection handle: that handle is platform-specific chrome, and a golden
  // that contains it is a golden about the handle rather than about the focus
  // ring it was written to pin.
  final TextEditingController _controller = TextEditingController.fromValue(
    const TextEditingValue(
      text: 'Academic Word List',
      selection: TextSelection.collapsed(offset: 18),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MxTextField(
    controller: _controller,
    label: 'Deck name',
    helperText: 'Shown in the deck list',
    errorText: widget.errorText,
    isEnabled: widget.isEnabled,
    shouldAutofocus: widget.shouldAutofocus,
    maxLength: 200,
  );
}

/// The dialog rendered inline rather than through `showDialog`, so no route
/// transition is in flight when the frame is captured.
class ConfirmDialogSpecimen extends StatelessWidget {
  const ConfirmDialogSpecimen({
    super.key,
    this.variant = MxConfirmDialogVariant.normal,
    this.title = 'Delete this deck?',
    this.message =
        'This removes 4 sub-decks and 11 cards. It cannot be undone.',
    this.confirmLabel = 'Delete',
  });

  final MxConfirmDialogVariant variant;
  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) => MxConfirmDialog(
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: 'Cancel',
    variant: variant,
    onConfirm: noop,
    onCancel: noop,
  );
}

/// Both sizes and both fills in one frame.
///
/// The complete bar is the half worth pinning: it is the only place the fill
/// leaves its own colour family, and the value label follows it — a change to
/// either shows up here.
class ProgressBarSpecimen extends StatelessWidget {
  const ProgressBarSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MxProgressBar(
              value: 0.62,
              label: '20 of 32 learned',
              valueLabel: '62%',
            ),
            SizedBox(height: AppSpacing.xl),
            MxProgressBar(
              value: 1,
              label: '88 of 88 learned',
              valueLabel: '100%',
              size: MxProgressBarSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty and in use, one above the other.
///
/// The second is the half worth pinning: the count and the clear button only
/// exist once something has been typed, and they are what the pill has to make
/// room for without pushing the text out of it.
/// The search pill with focus: the paper fill and the `primary` edge, the
/// query and the count. Autofocused rather than tapped, so the frame carries
/// no ripple.
class SearchFieldFocusedSpecimen extends StatelessWidget {
  const SearchFieldFocusedSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: MxSearchField(
            value: 'nouns',
            onChanged: _ignore,
            hintText: 'Search in Academic Word List',
            semanticLabel: 'Search this deck',
            resultCount: 7,
            clearSemanticLabel: 'Clear search',
            shouldAutofocus: true,
          ),
        ),
      ),
    );
  }

  static void _ignore(String _) {}
}

/// A field with a trailing action, in its error state: the border and the
/// `+` beside it must agree (#433 F4).
class TextFieldSuffixErrorSpecimen extends StatefulWidget {
  const TextFieldSuffixErrorSpecimen({super.key});

  @override
  State<TextFieldSuffixErrorSpecimen> createState() =>
      _TextFieldSuffixErrorSpecimenState();
}

class _TextFieldSuffixErrorSpecimenState
    extends State<TextFieldSuffixErrorSpecimen> {
  final TextEditingController _controller = TextEditingController(
    text: 'grammar',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MxTextField(
    controller: _controller,
    label: 'Add a tag',
    errorText: 'This card already has that tag',
    maxLength: 30,
    trailingAction: MxTextFieldAction(
      icon: Icons.add,
      semanticLabel: 'Add this tag',
      onPressed: () {},
    ),
  );
}

/// The multiline recipe — five of thirteen callers, and no golden showed one.
class TextFieldMultilineSpecimen extends StatefulWidget {
  const TextFieldMultilineSpecimen({super.key});

  @override
  State<TextFieldMultilineSpecimen> createState() =>
      _TextFieldMultilineSpecimenState();
}

class _TextFieldMultilineSpecimenState
    extends State<TextFieldMultilineSpecimen> {
  final TextEditingController _controller = TextEditingController(
    text:
        'present, appearing, or found everywhere — a meaning long enough to '
        'take a second line',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MxTextField(
    controller: _controller,
    label: 'Back',
    helperText: 'Two languages, comma-separated',
    maxLength: 240,
    minLines: 3,
    maxLines: 5,
  );
}

class SearchFieldSpecimen extends StatelessWidget {
  const SearchFieldSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MxSearchField(
              value: '',
              onChanged: _ignore,
              hintText: 'Search your whole library',
              semanticLabel: 'Search your library',
              clearSemanticLabel: 'Clear search',
            ),
            SizedBox(height: AppSpacing.xl),
            MxSearchField(
              value: 'nouns',
              onChanged: _ignore,
              hintText: 'Search in Academic Word List',
              semanticLabel: 'Search this deck',
              resultCount: 7,
              clearSemanticLabel: 'Clear search',
            ),
          ],
        ),
      ),
    );
  }

  static void _ignore(String _) {}
}

/// The session bar, twice: an ordinary word and one long enough to be cut.
///
/// **Its whole reason to be pinned is the two ends of the row.** The ✕ hangs
/// into the gutter so its glyph lands *at* it, the figure stops at the gutter,
/// and the track takes everything between — three relationships that no
/// assertion about a single widget can hold, and that a wrapper adding padding
/// silently breaks. So the specimen is deliberately unpadded horizontally: that
/// is the region the bar is designed for, and a golden taken inside a gutter
/// would record the layout it must never be given.
class SessionTopBarSpecimen extends StatelessWidget {
  const SessionTopBarSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: <Widget>[
            MxSessionTopBar(
              label: 'Browse',
              progress: 0.3,
              trailing: Text('3 / 10'),
              onClose: _noop,
              closeLabel: 'Close session',
            ),
            SizedBox(height: AppSpacing.xl),
            MxSessionTopBar(
              label: 'Ghép cặp từ và nghĩa',
              progress: 0.85,
              trailing: Text('0:12'),
              onClose: _noop,
              closeLabel: 'Close session',
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

/// The row in its four resting states on one sheet — rest, selected,
/// disabled, and the intersection nothing pictured: selected + disabled.
/// One image, one comparison, instead of three files and a gap (#431 §24).
class ListTileStatesSpecimen extends StatelessWidget {
  const ListTileStatesSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: OnSheetSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MxListTile(
              title: 'Front → back',
              subtitle: 'Show the term, recall the meaning',
              leading: Icon(Icons.radio_button_unchecked),
              isSelected: false,
              onTap: _noop,
            ),
            MxListTile(
              title: 'Back → front',
              subtitle: 'Show the meaning, recall the term',
              leading: Icon(Icons.radio_button_checked),
              isSelected: true,
              onTap: _noop,
            ),
            MxListTile(
              title: 'Mixed',
              subtitle: 'Not available for this deck',
              leading: Icon(Icons.radio_button_unchecked),
              isSelected: false,
              isEnabled: false,
              onTap: _noop,
            ),
            MxListTile(
              title: 'Picked, then locked',
              subtitle: 'A choice held while a request is in flight',
              leading: Icon(Icons.radio_button_checked),
              isSelected: true,
              isEnabled: false,
              onTap: _noop,
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}
