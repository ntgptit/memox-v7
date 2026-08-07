import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

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
          Text('Ephemeral', style: texts.headlineMedium),
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
        Text('ephemeral', style: texts.headlineMedium),
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

/// The pill group, over the hint it sits beside on the deck list.
///
/// **The reference line is the specimen, not decoration.** `MxPillButton` had no
/// golden at all until the weight it borrowed from the button was measured off a
/// device render — and a golden holding only pills would have recorded 600 as
/// correct, because a weight has nothing to be wrong against on its own. Both
/// rungs here are 14px, so the picture answers one question: does the control
/// out-shout the text it belongs to?
///
/// Selected and unselected together, because the label colour swaps with the
/// fill and only one of the two states would otherwise be pinned.
class PillGroupSpecimen extends StatelessWidget {
  const PillGroupSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Search your whole library',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                MxPillButton(
                  label: 'All decks',
                  icon: Icons.filter_list,
                  isSelected: false,
                  onPressed: _noop,
                ),
                MxPillButton(
                  label: 'Due only',
                  icon: Icons.filter_list,
                  isSelected: true,
                  onPressed: _noop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

/// Empty and in use, one above the other.
///
/// The second is the half worth pinning: the count and the clear button only
/// exist once something has been typed, and they are what the pill has to make
/// room for without pushing the text out of it.
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
            ),
            SizedBox(height: AppSpacing.xl),
            MxSearchField(
              value: 'nouns',
              onChanged: _ignore,
              hintText: 'Search in Academic Word List',
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
