# MemoX v3 traceability

| | |
|---|---|
| **Status** | active |
| **Purpose** | Source provenance, validation and implementation-order metadata from the handoff. |
| **Scope** | Imported MemoX v3 Flutter-handoff material only |
| **Source of truth for** | Traceability metadata for this imported v3 handoff. |
| **Depends on** | `docs/document-conventions.md` |
| **Updated by task** | v3-handoff export |
| **Last updated** | 2026-09-21 |

---
| Field | Value |
|---|---|
| generated | 2026-09-21T08:14:06.210Z |
| source | ui_kits/mobile/v3/spec.js (facts: widgets.js · tokens: colors_and_type.css) |
| contract | docs/MEMOX_DESIGN_TO_FLUTTER_SPEC_TEMPLATE.md |
| warning | Snapshot. Regenerate after any token, widget or template change — never hand-edit. |
| usage | Run in this order: foundations → themeHandoff → IMPLEMENT_COMPONENT entries → screen handoffs. HANDOFF MODE stays FOUNDATIONS / COMPONENT / SCREEN; themeHandoff is an implementation prerequisite, not a fourth mode. Widget specs omit the token/colour/type/composition sections on purpose. |

## canonicalSources

| Field | Value |
|---|---|
| a | themeRegistry — source of truth for THEME SEMANTIC BINDING: kind, value, destination, alias evidence, derivation, computed usageStatus, computed implementationDisposition, invariant flag |
| b | widgets[*].themeRoleUsage — source of truth for COMPONENT THEME CONSUMPTION: slot, state, access, role / childComponent+childConfiguration / input, structured treatment |
| foundations | FOUNDATIONS remains authoritative for typography, spacing, geometry, sizing and motion. This step BINDS those values to the repository theme; it does not author them. |
| generatedViews | themeHandoff.views.* and every theme table inside themeHandoff.spec / widgets[*].spec are rendered FROM a and b |
| independentDuplicateSemanticSources | 0 |

## implementationOrder

- FOUNDATIONS
- THEME_BINDING
- SHARED_COMPONENTS
- SCREENS

## validation

### tokenClosure

| Field | Value |
|---|---|
| ok | true |

#### unresolved

### crossLayerDimensionClasses

| Field | Value |
|---|---|
| ok | true |

#### mismatches

—

### themeRegistryIntegrity

| Field | Value |
|---|---|
| totalRoles | 91 |
| ok | true |
| note | One canonical record per semantic role. A role defined in two authored tables, or referenced by a component but absent from the registry, fails here. |

#### duplicateRoles

—

#### missingRequiredFields

—

#### conflictingDefinitions

—

#### unknownRoleReferences

—

### m3RoleDispositionCoverage

| Field | Value |
|---|---|
| canonicalRoleCount | 45 |
| v3Defined | 33 |
| repoPreserved | 12 |
| ok | true |
| note | §8: M3 roles keep V3_DEFINED / REPO_PRESERVED. BIND_NOW / PRESERVE_ONLY never replaces that model, and the canonical role set stays complete regardless of consumer count. |

#### missing

—

#### duplicates

—

#### bindNowPreserveOnlyApplied

—

### foundationTypographyFidelity

| Field | Value |
|---|---|
| rolesCompared | 7 |
| ok | true |
| note | Both tables render from TYPE_SCALE; the theme step binds typography and never authors it. |

#### mismatches

—

### foundationSemanticRoleCoverage

| Field | Value |
|---|---|
| total | 91 |
| nonM3 | 46 |
| ok | true |
| note | Closure over colors_and_type.css: every non-M3 colour token the design declares has exactly one registry record, so a token added to the CSS cannot slip through unclassified. |

#### counts

| Field | Value |
|---|---|
| M3_COLOR | 45 |
| MEMOX_SEMANTIC_COLOR | 15 |
| M3_ALIAS | 8 |
| DERIVED_COLOR | 8 |
| DECORATION | 7 |
| STATE_TOKEN | 3 |
| EFFECT_TOKEN | 2 |
| COMPONENT_INPUT | 2 |
| NONE | 1 |

#### usageStatus

| Field | Value |
|---|---|
| DIRECTLY_CONSUMED | 45 |
| FOUNDATION_DEFINED_UNUSED | 43 |
| INDIRECTLY_CONSUMED | 3 |

#### unclassified

—

### foundationSemanticUsageStatus

| Field | Value |
|---|---|
| masteryActive | true |
| masteryStatus | DIRECTLY_CONSUMED |
| ok | true |
| note | §6: deriving an UNUSED colour from a role does not make that role consumed. Status is computed from the consumption graph by fixpoint, never authored. |

#### incorrectDirect

—

#### incorrectIndirect

—

#### incorrectUnused

—

#### masteryEvidence

- StudyTopBar.progress fill passes it as accent
- StudyTopBar.mode badge label passes it as accent
- StudyTopBar.mode badge fill passes it as accent

#### unusedButDeriving

- success → derives success-soft (all inactive)

### implementationDispositionCoverage

| Field | Value |
|---|---|
| bindableRoles | 43 |
| ok | true |
| note | Computed from usageStatus: an unused Foundation semantic is PRESERVE_ONLY, so it never forces an unused runtime theme field. |

#### bindNow

- mastery
- warning
- on-warning
- status-new
- status-learning
- status-reviewing
- status-mastered
- error-fill
- on-error-fill
- bg
- surface-muted
- surface-raised
- progress-track
- text-secondary
- danger-soft
- danger-border
- warning-soft
- surface-hero
- chrome-glass
- shadow-soft
- shadow-card
- shadow-chrome
- shadow-fab
- border-ghost
- op-disabled
- op-press
- op-glass
- glass-blur

#### preserveOnly

- success
- streak
- on-streak
- mastery-fixed
- on-danger
- text-muted
- badge-bg
- danger
- text-primary
- primary-soft
- primary-border
- success-soft
- shadow-none
- border-strong
- op-hover

#### missing

—

#### invalid

—

#### statusDispositionMismatch

—

#### exemptKinds

- M3_COLOR (keeps V3_DEFINED / REPO_PRESERVED)
- COMPONENT_INPUT (instance input, never a theme field)
- NONE (absence of a value)

### roleKindClosure

| Field | Value |
|---|---|
| ok | true |
| note | §36: the registry owns classification. A usage record reads its kind from the registry classifier and cannot assign its own. |

#### vocabulary

- M3_COLOR
- MEMOX_SEMANTIC_COLOR
- M3_ALIAS
- DERIVED_COLOR
- DECORATION
- STATE_TOKEN
- EFFECT_TOKEN
- NONE
- COMPONENT_INPUT

#### counts

| Field | Value |
|---|---|
| M3_COLOR | 45 |
| MEMOX_SEMANTIC_COLOR | 15 |
| M3_ALIAS | 8 |
| DERIVED_COLOR | 8 |
| DECORATION | 7 |
| STATE_TOKEN | 3 |
| EFFECT_TOKEN | 2 |
| COMPONENT_INPUT | 2 |
| NONE | 1 |

#### invalidRegistryKinds

—

#### invalidUsageKinds

—

#### registryMismatches

—

### semanticAliasAssertions

| Field | Value |
|---|---|
| aliases | 8 |
| ok | true |
| note | An M3_ALIAS requires BOTH value equality in every theme AND semantic equivalence. on-danger fails the first test (Dark differs from onError) and text-muted fails the second (ink vs edge), so both stay MEMOX_SEMANTIC_COLOR however their values compare. |

#### valueMismatches

—

#### semanticMismatches

—

#### aliasEvidence

##### bg

| Field | Value |
|---|---|
| target | surface |
| valueMatch | true |
| semanticMatch | true |
| evidence | the page ground IS the surface role; the kit renames it for readability only |

##### surface-muted

| Field | Value |
|---|---|
| target | surfaceContainerLow |
| valueMatch | true |
| semanticMatch | true |
| evidence | the input / Note resting fill is that step of the same surface ladder |

##### surface-raised

| Field | Value |
|---|---|
| target | surfaceContainerLowest |
| valueMatch | true |
| semanticMatch | true |
| evidence | the card fill is that surface step in BOTH themes (#FFFFFF light / #131A3A dark) — no separate property, no brightness branch |

##### progress-track

| Field | Value |
|---|---|
| target | surfaceContainerHigh |
| valueMatch | true |
| semanticMatch | true |
| evidence | an unfilled track is a surface step, authored as that role |

##### badge-bg

| Field | Value |
|---|---|
| target | surfaceContainer |
| valueMatch | true |
| semanticMatch | true |
| evidence | a surface-ladder step authored as surfaceContainer. It is NOT the current badge fill: the tonal Badge tints its own tone at 12% and nothing in v3 reads this token. The alias evidence is the surface step, not a badge treatment. |

##### danger

| Field | Value |
|---|---|
| target | error |
| valueMatch | true |
| semanticMatch | true |
| evidence | destructive FOREGROUND semantics — the same role as error, renamed for product vocabulary |

##### text-primary

| Field | Value |
|---|---|
| target | onSurface |
| valueMatch | true |
| semanticMatch | true |
| evidence | primary ink IS onSurface |

##### text-secondary

| Field | Value |
|---|---|
| target | onSurfaceVariant |
| valueMatch | true |
| semanticMatch | true |
| evidence | secondary ink IS onSurfaceVariant |

#### regressionGuards

| Field | Value |
|---|---|
| on-danger | MEMOX_SEMANTIC_COLOR |
| text-muted | MEMOX_SEMANTIC_COLOR |

#### regressions

—

### themeInvariantAssertions

| Field | Value |
|---|---|
| scope | V3-authored standard M3 colour roles |
| masteryFixedInvariant | false |
| masteryFixedValue | #C7F2D8 / #1F4A37 |
| ok | true |
| note | Scoped claim: among the V3-authored standard M3 colour roles, exactly these two are intentionally invariant. Roles in equalValuesButNotInvariant share a value across themes WITHOUT being invariant — reported so nobody promotes coincidence into a contract. |

#### invariantRoles

- inverseSurface
- onInverseSurface

#### mismatches

—

#### flaggedOutsideScope

—

#### equalValuesButNotInvariant

- on-streak
- on-error-fill

#### regressions

—

### implementationRouting

| Field | Value |
|---|---|
| ok | true |
| note | §1: BIND_NOW means the current V3 needs the semantic, not that it belongs in the MemoX semantic extension. Every registry entry carries exactly one destination derived from its kind; aliases, NONE and COMPONENT_INPUT store nothing. |

#### destinations

| Field | Value |
|---|---|
| M3_COLOR | ColorScheme |
| M3_ALIAS | ColorScheme — resolve to the target role, no new field |
| MEMOX_SEMANTIC_COLOR | the existing MemoX semantic-colour mechanism |
| DERIVED_COLOR | central colour derivation |
| DECORATION | the decoration / token mechanism |
| STATE_TOKEN | the global state-token / policy mechanism |
| EFFECT_TOKEN | the effect / token mechanism |
| NONE | no theme field |
| COMPONENT_INPUT | no global theme field — a per-instance parameter |

#### bindNowByDestination

##### the existing MemoX semantic-colour mechanism

- mastery
- warning
- on-warning
- status-new
- status-learning
- status-reviewing
- status-mastered
- error-fill
- on-error-fill

##### ColorScheme — resolve to the target role, no new field

- bg
- surface-muted
- surface-raised
- progress-track
- text-secondary

##### central colour derivation

- danger-soft
- danger-border
- warning-soft
- surface-hero
- chrome-glass

##### the decoration / token mechanism

- shadow-soft
- shadow-card
- shadow-chrome
- shadow-fab
- border-ghost

##### the global state-token / policy mechanism

- op-disabled
- op-press

##### the effect / token mechanism

- op-glass
- glass-blur

#### storageKinds

- M3_COLOR
- MEMOX_SEMANTIC_COLOR
- DERIVED_COLOR
- DECORATION
- STATE_TOKEN
- EFFECT_TOKEN

#### wrongDestination

—

#### missingDestination

—

#### duplicateStorage

—

#### handoffPhrasing

—

### tokenValueSingleSource

| Field | Value |
|---|---|
| componentOwnedTintsAllowed | 16 |
| ok | true |
| note | §4: op-disabled / op-press / op-hover / op-glass are authored once in themeRegistry. Component records reference the token (treatment APPLY_TOKEN) rather than duplicating the number, while component-owned tints (StatusBadge 12%, BottomNav 14/20%, IconTile 12%) legitimately keep their own literals. |

#### globalTokens

| Field | Value |
|---|---|
| op-disabled | 0.38 |
| op-press | 0.12 |
| op-hover | 0.08 |
| op-glass | 0.84 |

#### duplicatedGlobalTokenValues

—

#### conflictingValues

—

#### notAppliedAsToken

—

#### tokensSharingAValue

—

### derivedColorConsistency

| Field | Value |
|---|---|
| ok | true |
| note | §21: the derivation is owned by Theme Binding, so a component consuming a DERIVED_COLOR carries treatment FULL_STRENGTH. A component that tints a BASE role itself binds that base role with an explicit treatment instead. Declared mix percentages are checked against the authored color-mix() expressions, and a derivation that names an opacity token must carry exactly that value. |

#### mismatches

—

#### doubleTinted

—

### effectTokenConsistency

| Field | Value |
|---|---|
| ok | true |
| note | §22–24: colour and effect are split. chrome-glass owns COLOUR only and references op-glass for the one authored 0.84; glass-blur owns the blur; the state layer keeps only disabled / pressed / hover. |

#### opGlass

| Field | Value |
|---|---|
| kind | EFFECT_TOKEN |
| value | 0.84 (both themes) |
| usageStatus | INDIRECTLY_CONSUMED |
| disposition | BIND_NOW |

##### consumers

- derives chrome-glass (ACTIVE)

#### chromeGlass

| Field | Value |
|---|---|
| kind | DERIVED_COLOR |
| source | surface |
| opacityToken | op-glass |
| value | rgba(247, 249, 254, 0.84) / rgba(10, 14, 39, 0.84) |

##### consumers

- BottomNav.bar surface

#### glassBlur

| Field | Value |
|---|---|
| kind | EFFECT_TOKEN |
| value | saturate(180%) blur(18px) (both themes) |

##### consumers

- BottomNav.bar blur · EFFECT (blur)

#### failures

—

#### colorOwningBlur

—

### perComponentThemeRoleUsage

| Field | Value |
|---|---|
| implementationComponentCount | 43 |
| themeRoleUsagePresentCount | 43 |
| themeRoleUsageMissing | 0 |
| themeRoleUsageMalformed | 2 |
| nonEmpty | 42 |
| countsAgree | true |
| ok | false |
| note | §33–35: counts are derived from the generated data, never hard-coded. Every record is checked for the fields its access mode requires; VIA_COMPONENT records are NOT required to carry a role. |

#### intentionallyEmpty

- screenscroll — gutter and scroll clearance only — paints no colour and consumes no theme role

#### missing

—

#### unresolvedRoles

#### invalidKinds

#### rawColorLeakage

#### structurallyIncomplete

- listsectionheader.trailing (VIA_COMPONENT) missing childConfiguration
- deckpickersheet.sheet (VIA_COMPONENT) missing childConfiguration

### themeRoleTreatmentCoverage

| Field | Value |
|---|---|
| records | 232 |
| treated | 53 |
| ok | false |
| note | treatment is a structured field parsed from a closed grammar: FULL_STRENGTH / TINT / OPACITY / MIX / BORDER / NO_FILL / EFFECT with parameters. A transformation can never survive as prose only, and a role reference never means full-strength paint. |

#### missing

—

#### unparsed

- segmentedtray.thumb shadow: "shadow"

#### conflicts

- segmentedtray.thumb shadow: UNPARSED

#### mandatoryCases

| Field | Value |
|---|---|
| StatusBadge.new.container | TINT 12% |
| StatusBadge.learning.container | TINT 12% |
| StatusBadge.reviewing.container | TINT 12% |
| StatusBadge.mastered.container | TINT 12% |
| IconTile.seeded.tile | TINT 12% |
| IconTile.default.tile | TINT 10% light / 16% dark |
| StudyTopBar.mode badge fill | TINT 10% |
| BottomNav.active.active indicator pill | TINT 14% light / 20% dark |
| Badge.tonal.container | TINT 12% |
| EmptyState.tile | RECORD NOT FOUND |
| Scrim.visible.barrier | OPACITY 0.45 |
| Button.disabled.whole control | APPLY_TOKEN (the token's own value) |

#### lostTransformations

- EmptyState.tile: expected TINT 10%, got RECORD NOT FOUND

### childComponentEncapsulation

| Field | Value |
|---|---|
| records | 16 |
| ok | true |
| note | §15–16: a parent selects the child's semantic variant (tone, enabled) and never names the role behind it. VIA_COMPONENT + role=primary / error-fill / op-disabled fails here. |

#### children

- FieldMessage
- IconTile
- ChipTrigger · Badge · Button
- Button
- BottomSheet
- ListRow
- EmptyState
- SheetActions

#### leaks

—

#### suspiciousConfiguration

—

#### byParent

##### TextField

- message row → FieldMessage (tone=error)

##### ListRow

- leading tile + glyph → IconTile (size=sm (tileSize) · variant=default, or seeded when the caller passes a seed)

##### SettingsRow

- leading tile + glyph → IconTile (size=md · variant=default)

##### ListSectionHeader

- trailing → ChipTrigger · Badge · Button (default configuration)

##### SheetActions

- cancel button → Button (tone=outline)
- confirm button → Button (tone=primary)
- destructive.confirm button → Button (tone=destructive)
- disabled.confirm button → Button (enabled=false)

##### InlineBanner

- actions → Button (size=compact)

##### DeckPickerSheet

- sheet → BottomSheet (default configuration)
- candidate rows → ListRow (tileSize=sm · trailing=chevron · disabled=when the target cannot accept the payload)
- empty → EmptyState (tone=neutral · compact=true)
- footer → SheetActions (divider=true)

##### EmptyState

- action → Button (tone=primary)

##### ErrorState

- action → Button (tone=primary)

##### FooterBar

- CTA → Button (tone=primary · width=block)

### directRoleConsumerAggregation

| Field | Value |
|---|---|
| roles | 45 |
| entries | 210 |
| ok | true |
| note | §28: the DIRECT index is generated FROM per-component usage and is the exact union of those records — nothing appended, nothing omitted. |

#### missingFromIndex

—

#### extraInIndex

—

#### duplicates

—

### componentCompositionAggregation

| Field | Value |
|---|---|
| parents | 10 |
| ok | true |
| note | §29: generated strictly from VIA_COMPONENT records; child configuration is never translated back into a raw theme role. |

#### accessCounts

| Field | Value |
|---|---|
| DIRECT | 210 |
| VIA_COMPONENT | 16 |
| COMPONENT_INPUT | 6 |

#### missingFromIndex

—

#### extraInIndex

—

#### duplicates

—

### componentInputAggregation

| Field | Value |
|---|---|
| entries | 6 |
| ok | true |
| note | §30: component inputs are indexed separately and never mixed into the DIRECT theme consumers. |

#### inputs

- accent
- seed

#### missingFromIndex

—

#### extraInIndex

—

#### duplicates

—

#### alsoInDirectIndex

—

### consumerDeduplication

| Field | Value |
|---|---|
| rawRecords | 233 |
| uniqueRecords | 232 |
| ok | false |
| note | §32: identity is component + slot + state + access for usages and the role id for derivation edges. Each unique consumer is emitted once — no "derives success-soft, derives success-soft". |

#### duplicateIdentityKeys

- OptionRow\|disabled\|whole row\|DIRECT

#### duplicatedIndexEntries

—

#### duplicatedDerivations

—

### roleConsumerFormatting

| Field | Value |
|---|---|
| roleBlocks | 45 |
| suffixRuleStated | true |
| ok | true |
| note | §53: structured role / kind: / consumers: lines with no fixed-width padding, every generated section says so in its heading, and the consumer index states the omitted-suffix rule so a bare role reference is never read as an unstated treatment. |

#### malformed

—

#### generatedViewMarked

| Field | Value |
|---|---|
| direct | true |
| composition | true |
| input | true |

#### unmarkedSections

—

### componentThemeRoleCoverage

| Field | Value |
|---|---|
| componentsWithUsage | 42 |
| of | 43 |
| ok | true |

#### missing

—

### rawColorInBindingRecords

| Field | Value |
|---|---|
| ok | true |
| note | §37: binding records carry semantic references only. Raw values live in the registry value column and in source traces. |

#### bindingRecords

—

#### dimensionRows

—

### treatmentClosure

| Field | Value |
|---|---|
| ok | false |
| note | The authored treatment grammar is closed. A new phrase fails here instead of silently degrading into prose. |

#### vocabulary

- FULL_STRENGTH
- TINT
- OPACITY
- MIX
- BORDER
- NO_FILL
- EFFECT
- APPLY_TOKEN
- FORWARD_UNCHANGED

#### counts

| Field | Value |
|---|---|
| FULL_STRENGTH | 163 |
| BORDER | 13 |
| EFFECT | 1 |
| TINT | 16 |
| NO_FILL | 3 |
| APPLY_TOKEN | 13 |
| OPACITY | 5 |
| UNPARSED | 1 |
| FORWARD_UNCHANGED | 1 |

#### unparsed

- segmentedtray.thumb shadow: "shadow"

### masteryResolution

| Field | Value |
|---|---|
| kind | MEMOX_SEMANTIC_COLOR |
| usageStatus | DIRECTLY_CONSUMED |
| implementationDisposition | BIND_NOW |
| distinctFrom | status-mastered (card lifecycle) — same authored value, different product concept; both kept, neither aliased to the other |
| ok | true |

#### directConsumers

- EmptyState.tone success.tile + glyph · TINT 10%

#### indirectConsumers

- StudyTopBar.progress fill passes it as accent
- StudyTopBar.mode badge label passes it as accent
- StudyTopBar.mode badge fill passes it as accent

### memoxSemanticDuplication

| Field | Value |
|---|---|
| ok | true |
| note | Generator-side check only. The theme handoff instructs the repo-aware agent to re-verify against the real ColorScheme after inspection. |

#### offenders

—

### themePrerequisite

| Field | Value |
|---|---|
| componentsBlockedUntil | THEME_BINDING |
| ok | true |

#### order

- FOUNDATIONS
- THEME_BINDING
- SHARED_COMPONENTS
- SCREENS

### typographySingleSource

| Field | Value |
|---|---|
| ok | true |
| inFoundations | true |
| inThemeBinding | true |
| note | Both tables render from TYPE_SCALE; a divergent hand-typed copy would fail this. |

### dependencyKinds

| Field | Value |
|---|---|
| ok | true |

#### vocabulary

- M3_COLOR
- MEMOX_SEMANTIC_COLOR
- M3_ALIAS
- DERIVED_COLOR
- DECORATION
- STATE_TOKEN
- EFFECT_TOKEN
- NONE
- COMPONENT_INPUT

#### usageStatusVocabulary

- DIRECTLY_CONSUMED
- INDIRECTLY_CONSUMED
- FOUNDATION_DEFINED_UNUSED

#### dispositionVocabulary

- BIND_NOW
- PRESERVE_ONLY

#### treatmentVocabulary

- FULL_STRENGTH
- TINT
- OPACITY
- MIX
- BORDER
- NO_FILL
- EFFECT
- APPLY_TOKEN
- FORWARD_UNCHANGED

#### accessModes

- DIRECT
- VIA_COMPONENT
- COMPONENT_INPUT

### dimensionClasses

| Field | Value |
|---|---|
| ok | true |

#### illegal

### disabledOpacity

| Field | Value |
|---|---|
| ok | true |

#### values

—

### touchMinimum

| Field | Value |
|---|---|
| ok | true |

#### values

- 52
- 48

### focusTreatment

| Field | Value |
|---|---|
| ok | true |

#### values

- 2px primary ring, offset 2

### analogyLooksLikeCode

| Field | Value |
|---|---|
| ok | true |

#### offenders

—

### ownershipLeakage

| Field | Value |
|---|---|
| ok | true |

#### widgets

—

### duplicateSemanticCandidates

| Field | Value |
|---|---|
| note | Reported, never merged — visual similarity is not identity. |

#### candidates

—

### perWidgetSelfCheck

| Field | Value |
|---|---|
| ok | false |

#### failures

##### selectioncheckbox

- touch geometry: painted 20 is below the 48 floor and no interactive-target row states the difference

##### segmentedtray

- touch geometry: painted 32 is below the 48 floor and no interactive-target row states the difference

##### stepper

- touch geometry: painted 36 is below the 48 floor and no interactive-target row states the difference

### dispositionCounts

| Field | Value |
|---|---|
| USE_PLATFORM | 2 |
| IMPLEMENT_COMPONENT | 43 |
| IMPLEMENT_UTILITY | 1 |
