import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Specimen widgets for the golden suite.
///
/// They live here rather than beside the cases because a specimen is a test
/// fixture, not a test: none of them asserts anything, and keeping them in
/// the same file pushed it past the size the guard allows.
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
        label: 'Review',
      ),
    ];

/// Takes focus on its first frame, so the golden captures the focused border
/// rather than the resting one.
class AutoFocusedField extends StatefulWidget {
  const AutoFocusedField({super.key});

  @override
  State<AutoFocusedField> createState() => _AutoFocusedFieldState();
}

class _AutoFocusedFieldState extends State<AutoFocusedField> {
  final FocusNode _node = FocusNode();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    focusNode: _node,
    autofocus: true,
    decoration: const InputDecoration(hintText: 'Search'),
  );
}

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

/// Opens a real modal bottom sheet on the first frame and leaves it open.
///
/// `pumpAndSettle` runs the open animation to completion before the frame is
/// captured, so the curve is finished rather than sampled mid-flight.
class HostedModalSheet extends StatefulWidget {
  const HostedModalSheet({super.key});

  @override
  State<HostedModalSheet> createState() => _HostedModalSheetState();
}

class _HostedModalSheetState extends State<HostedModalSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => const MxActionSheet(
            title: 'Add to this deck',
            actions: <MxActionSheetAction>[
              MxActionSheetAction(
                label: 'Create card',
                icon: Icons.note_add_outlined,
                onPressed: noop,
              ),
              MxActionSheetAction(
                label: 'Move',
                icon: Icons.drive_file_move_outlined,
                isEnabled: false,
                onPressed: noop,
              ),
              MxActionSheetAction(
                label: 'Delete',
                icon: Icons.delete_outline,
                variant: MxActionSheetActionVariant.destructive,
                onPressed: noop,
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}

/// Moves focus onto its child on the first frame, with the keyboard highlight
/// strategy forced on.
///
/// Without the strategy Flutter suppresses the focus ring -- the widget is
/// focused and the golden shows nothing, which would pin the absence of the
/// indicator instead of its appearance.
class FocusedOnFirstFrame extends StatefulWidget {
  const FocusedOnFirstFrame({required this.child, super.key});

  final Widget child;

  @override
  State<FocusedOnFirstFrame> createState() => _FocusedOnFirstFrameState();
}

class _FocusedOnFirstFrameState extends State<FocusedOnFirstFrame> {
  late final FocusHighlightStrategy _previous;

  @override
  void initState() {
    super.initState();
    _previous = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).nextFocus();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.highlightStrategy = _previous;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
