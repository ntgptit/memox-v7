import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_alert_dialog.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'mx_stress_selection_specimens.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_dialog_tone.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_form_dialog.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
import 'package:memox/shared/widgets/mx_metric_well.dart';
import 'package:memox/shared/widgets/mx_pressable.dart';
import 'package:memox/shared/widgets/mx_feedback_band.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_session_top_bar.dart';
import 'package:memox/shared/widgets/mx_text_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/core/theme/extensions/app_ink.dart';
import 'package:memox/shared/widgets/mx_hero_card.dart';

/// The specimen set for the stress suite: every shared component, built with
/// copy long enough to break a layout.
///
/// Separate from the cases for the same reason as `golden_specimens.dart` — a
/// specimen asserts nothing, and the two together exceed the file size the guard
/// allows.
///
/// **The copy is Vietnamese on purpose.** It is one of the app's two locales, it
/// runs about 25% longer than the English for the same sentence, and its
/// diacritics raise the line box — so a Column sized against an English string
/// overflows here and nowhere else. A test written with `'Lorem ipsum'` proves
/// the layout survives a language the app does not ship.
const String kLongTitle =
    'Bộ thẻ từ vựng tiếng Nhật trình độ N2 dành cho kỳ thi năng lực';

const String kLongMessage =
    'Thao tác này sẽ xoá vĩnh viễn 4 bộ thẻ con và 11 thẻ khỏi thiết bị này. '
    'Toàn bộ tiến trình học của các thẻ đó cũng sẽ mất và không thể phục hồi '
    'lại được bằng bất kỳ cách nào.';

const String kLongLabel = 'Xoá vĩnh viễn toàn bộ bộ thẻ này';

void _noop() {}

void _noopIndex(int index) {}

/// One component under stress, with whether it is meant to be tappable.
///
/// `isInteractive` drives the tap-target assertion rather than a second list, so
/// a component added here cannot be silently left out of the accessibility half.
class MxStressSpecimen {
  const MxStressSpecimen({
    required this.name,
    required this.build,
    this.isInteractive = false,
    this.needsBoundedHeight = false,
  });

  final String name;
  final Widget Function() build;

  /// Whether the specimen contains something a finger is supposed to hit.
  final bool isInteractive;

  /// Whether it fills its parent and so must be given a box rather than centred.
  ///
  /// `MxNavigationBar` and the two full-surface states size themselves to the
  /// space they are handed; centring them in an unbounded box measures nothing.
  final bool needsBoundedHeight;
}

/// Every shared component. Adding one here is how it enters the stress suite —
/// `mx_stress_test.dart` asserts this list covers `lib/shared/widgets/`.
List<MxStressSpecimen> stressSpecimens() => <MxStressSpecimen>[
  ...selectionStressSpecimens(),
  MxStressSpecimen(
    name: 'MxActionButton',
    build: () => const MxActionButton(
      label: kLongLabel,
      onPressed: _noop,
      icon: Icons.delete,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxActionButton (loading)',
    build: () => const MxActionButton(
      label: kLongLabel,
      onPressed: _noop,
      isLoading: true,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // The error pair at the stress width: the one fill whose palette is not
    // the brand's, and the variant #432 found untested at 320 × 2.0.
    name: 'MxActionButton (destructive)',
    build: () => const MxActionButton(
      label: kLongLabel,
      onPressed: _noop,
      variant: MxActionButtonVariant.destructive,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // 40 drawn, 48 hit, `label-md`: the deck row's verb, with the play glyph
    // Study Home gives it. Compact had no stress specimen at all.
    name: 'MxActionButton (compact)',
    build: () => const MxActionButton(
      label: kLongLabel,
      onPressed: _noop,
      icon: Icons.play_arrow,
      size: MxActionButtonSize.compact,
      variant: MxActionButtonVariant.secondary,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // Two long labels, because the pair's promise is that they come out the
    // same size however unequal the copy is — and the stress width is where an
    // even split is tightest.
    name: 'MxButtonPair',
    build: () => const MxButtonPair(
      primary: MxActionButton(label: kLongLabel, onPressed: _noop),
      secondary: MxActionButton(
        label: kLongTitle,
        onPressed: _noop,
        variant: MxActionButtonVariant.secondary,
      ),
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // The FAB paints no text of its own, so the long-label stress runs through
    // its tooltip/semantic name rather than its layout.
    name: 'MxFab',
    build: () =>
        const MxFab(icon: Icons.add, label: kLongLabel, onPressed: _noop),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // Non-interactive glyph: the stress is that the long accessible name
    // reaches semantics, not layout.
    name: 'MxIcon',
    build: () => const MxIcon(Icons.flag_outlined, semanticLabel: kLongLabel),
  ),
  MxStressSpecimen(
    // The pressable owns no copy — the stress is that its 48 floor holds while
    // the child it wraps wraps.
    name: 'MxPressable',
    build: () => const MxPressable(
      onTap: _noop,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(kLongLabel),
      ),
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxIconButton',
    build: () => const MxIconButton(
      icon: Icons.delete_outline,
      semanticLabel: kLongLabel,
      onPressed: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // A long hint is the case that breaks a search bar: the placeholder has to
    // ellipsize inside the pill rather than push the clear button off the end.
    name: 'MxSearchField',
    build: () => const MxSearchField(
      value: '',
      onChanged: _ignoreText,
      hintText: kLongLabel,
      semanticLabel: 'Search',
      clearSemanticLabel: 'Clear search',
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // A long label beside a long figure is the case that breaks a progress
    // header: the label has to ellipsize and the figure must not, or the
    // percentage is what falls off the end of the row.
    name: 'MxProgressBar',
    build: () =>
        const MxProgressBar(value: 0.62, label: kLongLabel, valueLabel: '62%'),
  ),
  MxStressSpecimen(
    // A mode name long enough to want the whole row is the case that breaks
    // this bar: the chip has to give way and ellipsize, because the figure
    // beside it is a count and a truncated count is a wrong one. The chip is
    // laid out inflexibly so the track gets the true remainder, so nothing in
    // the row would yield on its own — the cap is what makes it.
    name: 'MxSessionTopBar',
    build: () => const MxSessionTopBar(
      label: kLongLabel,
      progress: 0.62,
      trailing: Text('12 / 240'),
      onClose: _noop,
      closeLabel: kLongLabel,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // Fixed-size by construction — a glyph in a padded pill — so the stress
    // here is that it stays that size when everything around it grows. A metric
    // anchor that scaled with the text would break the grid it anchors.
    name: 'MxMetricWell',
    build: () => const MxMetricWell(
      icon: Icons.event_busy,
      tint: AppInk.onErrorContainer,
    ),
  ),
  MxStressSpecimen(
    // The pair under one specimen: the panel measures, the primary reads. At
    // 320 the card is 288dp, under the tier, so the long label runs the full
    // width instead of stranding itself at one end.
    name: 'MxHeroCard',
    build: () => MxHeroCard(
      builder: (BuildContext context, bool isCramped) => MxCard.accent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(kLongTitle),
            MxHeroPrimary(
              label: kLongLabel,
              onPressed: _noop,
              isCramped: isCramped,
            ),
          ],
        ),
      ),
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxCard',
    build: () => const MxCard.raised(child: Text(kLongMessage)),
  ),
  MxStressSpecimen(
    name: 'MxCard (tappable)',
    build: () => const MxCard.raised(onTap: _noop, child: Text(kLongMessage)),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // Title and message both long, and the action present: the band's whole job
    // is to stay readable while the copy grows, and the retry sits under the
    // message rather than beside it precisely so it can.
    name: 'MxFeedbackBand',
    build: () => const MxFeedbackBand(
      title: kLongTitle,
      message: kLongMessage,
      actionLabel: kLongLabel,
      onAction: _noop,
    ),
    // Title, message and a retry stacked at 2.0x on a 320 screen is taller than
    // the centred slot, the same reason `MxEmptyState` takes this.
    needsBoundedHeight: true,
  ),
  MxStressSpecimen(
    // A readout, not a control: no target to reach, so the stress is the long
    // word at 2.0x inside a pill that must not clip it.
    name: 'MxBadge',
    build: () => const MxBadge(label: kLongLabel),
  ),
  MxStressSpecimen(
    // A pill's label is short by design, so the stress here is the *selected*
    // pair plus an icon: that is the widest it gets, and the tap target still has
    // to reach the minimum — the widget's own now, grown outside the ring.
    name: 'MxPillButton',
    build: () => const MxPillButton(
      label: kLongLabel,
      icon: Icons.filter_list,
      isSelected: true,
      onPressed: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // The interesting stress is the tap target, not the width. This button
    // draws no padding at all, so nothing but `minimumSize` is holding it to
    // 48 — and a long label that wraps to its two-line ceiling is where a
    // height floor is most likely to be quietly overridden by the content.
    name: 'MxTextButton',
    build: () => const MxTextButton(label: kLongLabel, onPressed: _noop),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // Ten steps, which is the deepest path BR-55 allows, with long labels. The
    // strip scrolls, so the stress here is not overflow but the tap target: each
    // step still has to clear the minimum once the row is that long.
    name: 'MxBreadcrumb',
    build: () => MxBreadcrumb(
      semanticLabel: 'Deck path',
      items: <MxBreadcrumbItem>[
        for (var i = 0; i < 10; i++)
          MxBreadcrumbItem(
            label: '$kLongLabel $i',
            onTap: i == 9 ? null : _noop,
          ),
      ],
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // The two states whose extra ink and fill are most likely to fail on a
    // squeezed row — #431 F18.1 found only the resting row stressed.
    name: 'MxListTile (selected)',
    build: () => const MxListTile(
      title: kLongTitle,
      subtitle: kLongLabel,
      leading: Icon(Icons.radio_button_checked),
      isSelected: true,
      onTap: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxListTile (disabled)',
    build: () => const MxListTile(
      title: kLongTitle,
      subtitle: kLongLabel,
      leading: Icon(Icons.style_outlined),
      trailing: Icon(Icons.chevron_right),
      isEnabled: false,
      onTap: _noop,
    ),
  ),
  MxStressSpecimen(
    name: 'MxListTile',
    build: () => const MxListTile(
      title: kLongTitle,
      subtitle: kLongMessage,
      leading: Icon(Icons.folder_outlined),
      trailing: Icon(Icons.chevron_right),
      onTap: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxEmptyState',
    build: () => const MxEmptyState(
      title: kLongTitle,
      message: kLongMessage,
      actionLabel: kLongLabel,
      onAction: _noop,
    ),
    isInteractive: true,
    needsBoundedHeight: true,
  ),
  MxStressSpecimen(
    name: 'MxErrorState',
    build: () => const MxErrorState(
      title: kLongTitle,
      message: kLongMessage,
      retryLabel: kLongLabel,
      onRetry: _noop,
    ),
    isInteractive: true,
    needsBoundedHeight: true,
  ),
  const MxStressSpecimen(
    name: 'MxLoadingState',
    build: _buildLoadingState,
    needsBoundedHeight: true,
  ),
  MxStressSpecimen(
    name: 'MxConfirmDialog',
    build: () => const MxConfirmDialog(
      title: kLongTitle,
      message: kLongMessage,
      confirmLabel: kLongLabel,
      cancelLabel: 'Huỷ bỏ thao tác',
      variant: MxConfirmDialogVariant.destructive,
      onConfirm: _noop,
      onCancel: _noop,
    ),
    isInteractive: true,
  ),
  // One action, so the footer is a single full-width button rather than a
  // pair — the case where a long label has nothing beside it to balance
  // against.
  MxStressSpecimen(
    name: 'MxAlertDialog',
    build: () => const MxAlertDialog(
      title: kLongTitle,
      message: kLongMessage,
      dismissLabel: kLongLabel,
      tone: MxDialogTone.error,
      onDismiss: _noop,
    ),
    isInteractive: true,
  ),
  // A form dialog carries a field *and* a failure line under it, so the case
  // that breaks it is the one where both are long at once.
  MxStressSpecimen(
    name: 'MxFormDialog',
    build: () => MxFormDialog(
      title: kLongTitle,
      confirmLabel: kLongLabel,
      cancelLabel: 'Huỷ bỏ thao tác',
      errorMessage: kLongMessage,
      onConfirm: _noop,
      onCancel: _noop,
      child: MxTextField(
        controller: TextEditingController(text: kLongLabel),
        label: 'Tên thẻ đánh dấu',
      ),
    ),
    isInteractive: true,
  ),
  // The toned header is a second layout, not a second colour: the icon takes
  // room out of the headline's row, so this is where a long Vietnamese title
  // meets a 320dp screen with 24dp of glyph already spent.
  MxStressSpecimen(
    name: 'MxConfirmDialog (toned)',
    build: () => const MxConfirmDialog(
      title: kLongTitle,
      message: kLongMessage,
      confirmLabel: kLongLabel,
      cancelLabel: 'Huỷ bỏ thao tác',
      variant: MxConfirmDialogVariant.destructive,
      tone: MxDialogTone.error,
      onConfirm: _noop,
      onCancel: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxActionSheet',
    build: () => const MxActionSheet(
      title: kLongTitle,
      actions: <MxActionSheetAction>[
        MxActionSheetAction(
          label: kLongLabel,
          onPressed: _noop,
          icon: Icons.delete_outline,
          variant: MxActionSheetActionVariant.destructive,
        ),
        MxActionSheetAction(
          label: 'Đổi tên bộ thẻ này thành tên khác',
          onPressed: _noop,
          icon: Icons.edit_outlined,
        ),
      ],
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxTextField',
    build: () => MxTextField(
      controller: TextEditingController(text: kLongTitle),
      label: 'Tên bộ thẻ từ vựng',
      helperText: kLongMessage,
      errorText: 'Tên bộ thẻ không được để trống hoặc chỉ chứa khoảng trắng',
    ),
    isInteractive: true,
  ),
  // Both branches of `isScrollable`, because they are different layouts and only
  // one of them can be wrong at a time.
  //
  // A fixed body that cannot fit MUST opt in. Writing this specimen with the
  // default first produced a 547px overflow at 320 x 2.0 — correct behaviour for
  // `isScrollable: false`, and a fair demonstration of how quiet the mistake is:
  // nothing throws, and portrait at 1.0x never shows it.
  MxStressSpecimen(
    name: 'MxContentShell',
    build: () => const MxContentShell(
      title: kLongTitle,
      isScrollable: true,
      actions: <Widget>[
        MxIconButton(
          icon: Icons.add,
          semanticLabel: 'Thêm bộ thẻ con mới',
          onPressed: _noop,
        ),
        MxIconButton(
          icon: Icons.more_vert,
          semanticLabel: 'Thao tác khác với bộ thẻ',
          onPressed: _noop,
        ),
      ],
      body: Column(
        children: <Widget>[
          Text(kLongMessage),
          Text(kLongMessage),
          Text(kLongMessage),
        ],
      ),
    ),
    isInteractive: true,
    needsBoundedHeight: true,
  ),
  // The default, with the body it is the default *for*: one that scrolls itself.
  // This is the case that must not be wrapped in another scroll view — it would
  // be handed unbounded height and fail outright rather than overflow.
  MxStressSpecimen(
    name: 'MxContentShell (self-scrolling body)',
    build: () => MxContentShell(
      title: kLongTitle,
      body: ListView(
        children: const <Widget>[
          Text(kLongMessage),
          Text(kLongMessage),
          Text(kLongMessage),
        ],
      ),
    ),
    needsBoundedHeight: true,
  ),
  MxStressSpecimen(
    name: 'MxNavigationBar',
    build: () => const MxNavigationBar(
      selectedIndex: 0,
      onDestinationSelected: _noopIndex,
      destinations: <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Bộ thẻ của tôi',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: 'Ôn tập hôm nay',
        ),
      ],
    ),
    isInteractive: true,
    needsBoundedHeight: true,
  ),
];

/// A `const` builder, so the specimen itself can be `const`.
Widget _buildLoadingState() =>
    const MxLoadingState(semanticsLabel: 'Đang tải danh sách bộ thẻ');

void _ignoreText(String _) {}
