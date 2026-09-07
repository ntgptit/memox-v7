"""The guard rules that hold Design System V1 must keep watching feature code.

`docs/design-system/v1-freeze.md` §2 names fourteen frozen contracts and, for
each, the guard rule or test that makes it red when broken. §3 then says that
weakening the thing watching a contract counts as changing the contract.

Nothing enforced that. The other probes in this directory check that a rule's
*pattern* still matches, and to do so they deliberately discard the rule's real
`scopes`, `include`, `exclude` and `enabled` before running it -- correct for
their purpose, and blind to this one. Measured against `no_raw_screen_chrome`
with a real `AppBar(` sitting in `lib/features/deck/presentation/screens/`:

    rule left alone          guard red     probes green
    exclude that directory   guard GREEN   probes green
    enabled: false           guard GREEN   probes green
    rule deleted             guard GREEN   probes RED

Three of the four ways to switch a frozen contract off left every gate green.
This file closes the two that survived, by reading the rule as the guard
resolves it -- scopes expanded, excludes merged, `enabled` honoured -- and
asserting it still covers feature code.

It deliberately asserts on *effect* rather than on spelling. An allowlist of
approved `exclude` entries would pass a rule excluded by some other spelling of
the same paths; asking "does this rule still see this file?" cannot.
"""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path

import pytest

from code_verification_guard.config.config_manager import ConfigManager
from code_verification_guard.scanner.file_scanner import FileScanner

REPO_ROOT = Path(__file__).resolve().parents[2]
RULESET = "memox-v7"

# The guard rules named in the Enforcement column of v1-freeze.md §2. The
# comment on each is the contract it holds; the freeze document is the source
# of truth, and this list is the machine-readable half of it.
FROZEN_CONTRACT_RULES = (
    # 2 -- retune within a role, never swap one M3 role for another
    "memox.design_token.no_raw_color",
    "memox_v7.design_system.color_scheme_arguments_are_m3_roles",
    "memox_v7.design_system.color_scheme_reads_are_m3_roles",
    # 4 -- type scale and the variable-font weight contract
    "memox_v7.design_system.no_bare_font_weight",
    "memox.design_token.no_raw_text_style",
    # 5 -- spacing / radius / sizing / stroke / elevation foundations
    "memox.design_token.no_raw_spacing_literal",
    "memox.design_token.no_raw_border_radius",
    "memox.design_token.no_raw_stroke_width",
    # 12 -- semantic text restyle policy
    "memox_v7.design_system.no_text_restyle",
    # 13 -- raw Material ownership policy
    "memox_v7.design_system.no_raw_button",
    "memox_v7.design_system.no_raw_widget",
    "memox_v7.design_system.no_raw_screen_chrome",
    "memox_v7.design_system.no_raw_sheet_route",
    "memox_v7.design_system.no_raw_loading_indicator",
    "memox_v7.design_system.no_raw_choice_chip",
)


def _resolved_rules() -> dict[str, dict]:
    """Load the ruleset the way the guard itself loads it.

    `ConfigManager` is what expands `scopes:` into concrete include/exclude
    globs and merges any rule-level `exclude` on top. Going through
    `RuleFactory` directly -- as the pattern probes do -- skips all of that,
    which is precisely the blindness this file exists to remove.
    """
    _, rule_configs = ConfigManager().load_ruleset_runtime(REPO_ROOT, RULESET, None)
    return {rule["id"]: rule for rule in rule_configs}


def _feature_screen_paths() -> list[str]:
    """One representative presentation file per feature under `lib/features/`.

    Read from the tree rather than hardcoded so a new feature is covered the
    day it lands. The paths need not exist -- glob matching is pure string
    work -- but they are shaped like the real ones so a scope that stops at,
    say, `screens/` is still caught.
    """
    features_root = REPO_ROOT / "lib" / "features"
    features = sorted(p.name for p in features_root.iterdir() if p.is_dir())

    # A silently empty list would make every assertion below vacuous.
    assert len(features) >= 8, f"expected the app's features, found {features}"

    return [
        f"lib/features/{feature}/presentation/screens/{feature}_list_screen.dart"
        for feature in features
    ]


def _watches(rule: dict, path: str) -> bool:
    """Whether the guard would scan `path` under this resolved rule."""
    if rule.get("enabled") is False:
        return False

    scanner = FileScanner()
    if not scanner.matches_any(path, rule.get("include", [])):
        return False

    return not scanner.matches_any(path, rule.get("exclude", []))


@pytest.mark.parametrize("rule_id", FROZEN_CONTRACT_RULES)
def test_frozen_contract_rule_still_exists(rule_id: str) -> None:
    rules = _resolved_rules()

    assert rule_id in rules, (
        f"{rule_id} holds a frozen contract in v1-freeze.md §2 and is gone from "
        f"the {RULESET} ruleset. Removing it is changing the contract (§3)."
    )


@pytest.mark.parametrize("rule_id", FROZEN_CONTRACT_RULES)
def test_frozen_contract_rule_is_enabled(rule_id: str) -> None:
    rule = _resolved_rules()[rule_id]

    assert rule.get("enabled") is not False, (
        f"{rule_id} is disabled. The guard stays green with it off, so this is "
        f"a frozen contract switched off silently."
    )


@pytest.mark.parametrize("rule_id", FROZEN_CONTRACT_RULES)
def test_frozen_contract_rule_watches_every_feature(rule_id: str) -> None:
    rule = _resolved_rules()[rule_id]

    unwatched = [path for path in _feature_screen_paths() if not _watches(rule, path)]

    assert unwatched == [], (
        f"{rule_id} no longer covers {unwatched}. An `exclude` or a narrowed "
        f"`scopes` leaves the guard green while the contract stops being held."
    )


def test_the_watch_check_is_not_vacuous() -> None:
    """Fault-inject, so a broken assertion cannot pass by doing nothing.

    Every test above would still pass if `_watches` always returned True. This
    one adds the exclude that was measured to slip past the guard and the
    pattern probes alike, and requires the check to notice.
    """
    rule = deepcopy(_resolved_rules()["memox_v7.design_system.no_raw_screen_chrome"])
    path = "lib/features/deck/presentation/screens/deck_list_screen.dart"
    assert _watches(rule, path)

    rule.setdefault("exclude", []).append("lib/features/deck/**")
    assert not _watches(rule, path)

    disabled = deepcopy(_resolved_rules()["memox_v7.design_system.no_raw_screen_chrome"])
    disabled["enabled"] = False
    assert not _watches(disabled, path)
