import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

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
    name: 'MxIconButton',
    build: () => const MxIconButton(
      icon: Icons.delete_outline,
      semanticLabel: kLongLabel,
      onPressed: _noop,
    ),
    isInteractive: true,
  ),
  MxStressSpecimen(
    name: 'MxCard',
    build: () => const MxCard(child: Text(kLongMessage)),
  ),
  MxStressSpecimen(
    name: 'MxCard (tappable)',
    build: () => const MxCard(onTap: _noop, child: Text(kLongMessage)),
    isInteractive: true,
  ),
  MxStressSpecimen(
    // A pill's label is short by design, so the stress here is the *selected*
    // pair plus an icon: that is the widest it gets, and the tap target still has
    // to reach the minimum once the chip is padded.
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
