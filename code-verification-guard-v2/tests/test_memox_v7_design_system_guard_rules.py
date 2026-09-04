"""Fault-injection probes for the memox-v7 design-system ratchets (A20.1 §9).

Every rule that lands for the Design System V1 closure ships three proofs:
a positive synthetic probe (the rule goes red on the thing it bans), a
comment false-positive probe (prose that names the thing stays green), and
the live-tree scan the CI guard performs. The first two live here.
"""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

import yaml

from code_verification_guard.factory.rule_factory import RuleFactory

REGISTRY_PATH = (
    Path(__file__).parents[1]
    / "registries"
    / "projects"
    / "memox-v7"
    / "rules"
    / "memox-design-system-rules.yaml"
)


def _rule_config(rule_id: str) -> dict:
    registry = yaml.safe_load(REGISTRY_PATH.read_text(encoding="utf-8"))
    for rule_config in registry.get("rules", []):
        if rule_config["id"] == rule_id:
            return deepcopy(rule_config)

    raise AssertionError(f"Rule not found: {rule_id}")


def _violations(rule_id: str, tmp_path: Path, source: str) -> list:
    source_path = (
        tmp_path / "lib" / "features" / "deck" / "presentation" / "screens" / "sample_screen.dart"
    )
    source_path.parent.mkdir(parents=True, exist_ok=True)
    source_path.write_text(source, encoding="utf-8")

    rule_config = _rule_config(rule_id)
    rule_config.pop("scopes", None)
    rule_config["include"] = ["lib/**/*.dart"]
    rule_config["exclude"] = []
    rule_config["enabled"] = True

    return RuleFactory().create(rule_config).check(tmp_path)


SCREEN_CHROME = "memox_v7.design_system.no_raw_screen_chrome"
CHOICE_CHIP = "memox_v7.design_system.no_raw_choice_chip"


def test_no_raw_screen_chrome_goes_red_on_a_raw_app_bar(tmp_path: Path) -> None:
    bad = """
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
    """
    assert _violations(SCREEN_CHROME, tmp_path, bad)


def test_no_raw_screen_chrome_goes_red_on_a_sliver_app_bar(tmp_path: Path) -> None:
    bad = """
    slivers: <Widget>[
      SliverAppBar(pinned: true, title: Text(title)),
    ],
    """
    assert _violations(SCREEN_CHROME, tmp_path, bad)


def test_no_raw_screen_chrome_ignores_prose_and_themes(tmp_path: Path) -> None:
    good = """
    // The shell used to build an AppBar( here; it now owns the chrome.
    /// A doc comment that says SliverAppBar( is still prose.
    final AppBarTheme theme = AppBarTheme(centerTitle: false);
    return MxContentShell(title: title, body: child);
    """
    assert not _violations(SCREEN_CHROME, tmp_path, good)


def test_no_raw_choice_chip_goes_red_on_a_raw_choice_chip(tmp_path: Path) -> None:
    bad = """
    ChoiceChip(label: Text(label), selected: isSelected, onSelected: onPick),
    ChoiceChip.elevated(label: Text(label), selected: false),
    """
    assert _violations(CHOICE_CHIP, tmp_path, bad)


def test_no_raw_choice_chip_leaves_the_allowed_chips_alone(tmp_path: Path) -> None:
    good = """
    // MxPillButton wraps a ChoiceChip( so features never build one.
    Chip(label: Text(tag.name), onDeleted: remove),
    ActionChip(avatar: const Icon(Icons.add), label: Text(add), onPressed: open),
    MxPillButton(label: label, isSelected: isSelected, onPressed: onPick),
    """
    assert not _violations(CHOICE_CHIP, tmp_path, good)


SHEET_ROUTE = "memox_v7.design_system.no_raw_sheet_route"
LOADING = "memox_v7.design_system.no_raw_loading_indicator"
RESTYLE = "memox_v7.design_system.no_text_restyle"


def test_no_raw_sheet_route_goes_red_on_a_raw_route(tmp_path: Path) -> None:
    bad = """
    final chosen = await showModalBottomSheet<DeckListSort>(
      context: context,
      builder: (sheetContext) => MxActionSheet(actions: actions),
    );
    showBottomSheet(context: context, builder: (_) => child);
    """
    assert _violations(SHEET_ROUTE, tmp_path, bad)


def test_no_raw_sheet_route_leaves_the_owner_and_prose_alone(tmp_path: Path) -> None:
    good = """
    // showModalBottomSheet( used to be called here; showMxSheet owns it.
    final chosen = await showMxSheet<DeckListSort>(
      context,
      builder: (sheetContext) => MxActionSheet(actions: actions),
    );
    """
    assert not _violations(SHEET_ROUTE, tmp_path, good)


def test_no_raw_loading_indicator_goes_red_on_a_bare_spinner(tmp_path: Path) -> None:
    bad = """
    child: const CircularProgressIndicator(),
    child: LinearProgressIndicator(),
    child: CircularProgressIndicator.adaptive(),
    """
    assert _violations(LOADING, tmp_path, bad)


def test_no_raw_loading_indicator_leaves_the_family_and_prose_alone(tmp_path: Path) -> None:
    good = """
    // A bare CircularProgressIndicator( announces nothing.
    child: MxLoadingState.inline(semanticsLabel: label),
    child: MxLoadingState(semanticsLabel: label),
    """
    assert not _violations(LOADING, tmp_path, good)


def test_no_raw_loading_indicator_excludes_the_determinate_ring() -> None:
    rule = _rule_config(LOADING)
    assert rule["exclude"] == [
        "**/card/presentation/widgets/sections/card_progress_panel_widget.dart"
    ]


def test_no_text_restyle_sees_all_four_spellings_across_lines(tmp_path: Path) -> None:
    for bad in (
        "style: context.texts.bodySmall?.copyWith(color: colors.error),",
        "style: context.textStyles.sectionLabel.copyWith(color: colors.onSurfaceVariant),",
        "style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),",
        """
    style: AppTypography.withWeight(
      context.texts.labelMedium!,
      FontWeight.w600,
    ).copyWith(
      color: ink,
    ),
    """,
    ):
        assert _violations(RESTYLE, tmp_path, bad), bad


def test_no_text_restyle_accepts_inked_and_prose(tmp_path: Path) -> None:
    good = """
    // texts.bodySmall!.copyWith( is the spelling this rule refuses.
    style: context.texts.bodySmall!.inked(context, AppInk.quiet),
    style: AppTypography.withWeight(
      context.texts.labelMedium!,
      FontWeight.w600,
    ).inked(context, AppInk.stated).copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    ),
    """
    assert not _violations(RESTYLE, tmp_path, good)
