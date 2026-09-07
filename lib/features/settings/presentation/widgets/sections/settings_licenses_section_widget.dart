import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';

/// The way into the open-source licences the app is obliged to show.
///
/// **An obligation, not a courtesy.** All three bundled faces are SIL Open Font
/// License 1.1, which requires the licence to travel with the software. The app
/// shipped the fonts and nothing else, so this row is what closes that — the
/// entries themselves are registered at startup by `registerFontLicenses`.
///
/// **Flutter's own page, not one written here.** `showLicensePage` already
/// lists every package in the tree, is localised through
/// `MaterialLocalizations`, scrolls and searches; a hand-built screen would be
/// a worse copy that also has to be kept in step with the dependency list.
///
/// Shaped exactly like the reminder entry above it — a label, a leading glyph
/// and a chevron the screen reader does not announce — because the two rows do
/// the same thing and a reader should not have to learn two grammars for it.
class SettingsLicensesSectionWidget extends StatelessWidget {
  const SettingsLicensesSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MxCard.raised(
      padding: MxCardPadding.none,
      child: MxListTile(
        title: context.l10n.settingsLicensesTitle,
        leading: const Icon(Icons.description_outlined),
        trailing: const ExcludeSemantics(child: MxIcon(Icons.chevron_right)),
        onTap: () => showLicensePage(
          context: context,
          applicationName: context.l10n.appTitle,
        ),
      ),
    );
  }
}
