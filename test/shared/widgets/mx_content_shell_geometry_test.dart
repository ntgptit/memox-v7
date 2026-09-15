import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_reading_column.dart';
import 'package:memox/shared/widgets/mx_scroll_end_inset.dart';

/// A20.1 P2-18 — the shell owns its geometry: the scrolled hairline, the
/// reading column, the scroll-end clearance and the two-line bar's height.
void main() {
  const tall = SizedBox(height: 4000, width: double.infinity);

  Future<void> pumpShell(
    WidgetTester tester, {
    Widget? subheader,
    Widget? fab,
    Widget? body,
    double textScale = 1,
    Widget? titleSubline,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: MxContentShell(
          title: 'Shell',
          subheader: subheader,
          titleSubline: titleSubline,
          floatingActionButton: fab,
          isScrollable: true,
          body: body ?? tall,
        ),
      ),
    );
  }

  Future<void> scroll(WidgetTester tester) async {
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  group('the scrolled hairline', () {
    testWidgets('sits on the bar when the bar is the whole chrome', (
      tester,
    ) async {
      await pumpShell(tester);
      expect(tester.widget<AppBar>(find.byType(AppBar)).shape, isNull);

      await scroll(tester);
      expect(tester.widget<AppBar>(find.byType(AppBar)).shape, isNotNull);
    });

    testWidgets('moves under the subheader band when there is one', (
      tester,
    ) async {
      await pumpShell(tester, subheader: const Text('band'));
      await scroll(tester);

      expect(tester.widget<AppBar>(find.byType(AppBar)).shape, isNull);
      final band = tester.widget<MxSubheaderBand>(find.byType(MxSubheaderBand));
      expect(band.isScrolled, isTrue);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(MxSubheaderBand),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).border, isNotNull);
      expect(box.position, DecorationPosition.foreground);
    });
  });

  group('the scroll-end inset', () {
    testWidgets('clears a floating action, gesture inset included', (
      tester,
    ) async {
      late double inset;
      await pumpShell(
        tester,
        fab: FloatingActionButton(onPressed: () {}, child: const Text('+')),
        body: Builder(
          builder: (context) {
            inset = mxScrollEndInsetOf(context);
            return tall;
          },
        ),
      );
      expect(inset, AppSpacing.fabScrollClearance);
    });

    testWidgets('is the ordinary gap without one, and outside a shell', (
      tester,
    ) async {
      late double inShell;
      await pumpShell(
        tester,
        body: Builder(
          builder: (context) {
            inShell = mxScrollEndInsetOf(context);
            return tall;
          },
        ),
      );
      expect(inShell, AppSpacing.lg);

      late double bare;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            bare = mxScrollEndInsetOf(context);
            return const SizedBox();
          },
        ),
      );
      expect(bare, AppSpacing.lg);
    });
  });

  group('the reading column', () {
    testWidgets('caps at the medium breakpoint and binds nothing below it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: MxReadingColumn(child: SizedBox.expand())),
        ),
      );
      expect(
        tester.getSize(find.byType(SizedBox)).width,
        AppBreakpoints.medium,
      );
      expect(MxReadingColumn.maxWidth, AppBreakpoints.medium);
    });
  });

  group('the two-line bar', () {
    testWidgets('reserves for the title the bar actually draws', (
      tester,
    ) async {
      Future<double> heightAt(double scale) async {
        await pumpShell(
          tester,
          textScale: scale,
          titleSubline: const Text('subline'),
        );
        return tester.getSize(find.byType(AppBar)).height;
      }

      final atCeiling = await heightAt(1.34);
      final aboveCeiling = await heightAt(2.0);
      // `AppBar` clamps its title at 1.34; the bar must not grow past what
      // that title needs.
      expect(aboveCeiling, atCeiling);
      expect(atCeiling, greaterThanOrEqualTo(AppSizing.touchTarget));
    });
  });
}
