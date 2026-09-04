import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';

import 'golden_specimens.dart';

/// Hosts that put a specimen into a state a still frame cannot otherwise reach.
///
/// Split from `golden_specimens.dart` when the pill specimen took that file past
/// the 400-line guard, on the seam it already had: a **specimen** is the thing
/// being photographed, a **host** is the stand it has to sit on. Nothing here
/// draws app UI — each one exists because focus, a route, or a highlight
/// strategy is a *behaviour*, and a golden captures one frame with no chance to
/// perform it.
///
/// The two rules that follow from that: a host owns a lifecycle and gives it
/// back (`dispose` restores what `initState` changed), and a host never decides
/// how anything looks.

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
