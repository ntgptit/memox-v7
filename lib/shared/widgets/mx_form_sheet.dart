import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/submit_state.dart';
import '../../core/theme/app_spacing.dart';

/// Shows a form in a bottom sheet with the keyboard inset applied.
///
/// **`isScrollControlled` and the view insets, both.** Without them the sheet is
/// capped at half the screen and the keyboard covers the submit button — a form
/// the user cannot submit without dismissing the keyboard first. That is a bug
/// this project has already had once, which is the argument for the function
/// existing at all rather than each caller configuring `showModalBottomSheet`
/// again.
///
/// [reset] is called from the tap that opens the form, **not** from a widget
/// life-cycle. Riverpod refuses a provider mutation during `build`, `initState`
/// or `dispose`, and resetting from `dispose` additionally races the
/// controller's own disposal: an `autoDispose` provider with no listeners left
/// is already gone by the time a scheduled callback runs. Clearing at the point
/// the form is shown is deterministic and gives the same guarantee — a reopened
/// form starts clean.
Future<void> showMxFormSheet(
  BuildContext context, {
  required Widget Function(BuildContext, WidgetRef, VoidCallback) builder,
  required void Function(ProviderContainer) reset,
}) {
  reset(ProviderScope.containerOf(context));

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SingleChildScrollView(
        child: Consumer(
          builder: (consumerContext, ref, _) => builder(
            consumerContext,
            ref,
            () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
  );
}

/// Closes its sheet the moment the operation reports that it should close.
///
/// Takes the state and a callback rather than a provider, because a feature's
/// write controllers are distinct generated provider types — several of them
/// families — and no single parameter type unifies them. Passing the values
/// keeps this widget honest about what it needs: a state to compare against,
/// and something to call.
///
/// **It reacts to the transition, not the value.** Reading the outcome alone
/// would fire on every rebuild that happens to see it and pop the sheet more
/// than once.
///
/// **And `shouldClose`, never "succeeded".** A form that saved and stayed open
/// for the next entry reports `SubmitOutcome.savedAndContinue`, and closing on
/// that is the bug the distinction exists to prevent — it would let an *add
/// another* form accept exactly one entry. Deck has no such form; the check was
/// written this way so that cloning it into one could not go wrong silently,
/// and Card's editor is that clone.
class MxFormHost<P extends Enum> extends StatefulWidget {
  const MxFormHost({
    required this.state,
    required this.onDone,
    required this.child,
    super.key,
  });

  final SubmitState<P> state;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<MxFormHost<P>> createState() => _MxFormHostState<P>();
}

class _MxFormHostState<P extends Enum> extends State<MxFormHost<P>> {
  @override
  void didUpdateWidget(MxFormHost<P> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.shouldClose && !oldWidget.state.shouldClose) {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
