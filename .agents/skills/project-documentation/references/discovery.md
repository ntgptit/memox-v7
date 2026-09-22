# Mandatory discovery

Complete these ordered steps on each new repository, with or without config:

1. **Instructions:** read applicable agent instructions and their reading order.
   Inspect existing AGENTS.md, CLAUDE.md, README, CONTRIBUTING or equivalents and
   scoped nested instructions; follow pointers. Missing names are not required files.
2. **Root:** inspect root structure, manifests, build/workspace config, ignore rules,
   version control, subprojects and submodules.
3. **Sources:** find actual roots from build inputs/content; map imports/entry points.
4. **Tests:** inspect runners, locations, fixtures, CI and intended versus run coverage.
5. **Docs:** inventory navigation, authority/status, generated areas and non-Markdown
   equivalents. No documentation is a valid context and a coverage gap.
6. **Stack:** inspect manifests/config/source for languages/dependencies/toolchain;
   retain conflicting versions and subproject differences.
7. **Persistence:** inspect dependencies, storage access, schemas/migrations/config.
   No schema file does not prove no database; record what was actually checked.
8. **Architecture:** compare structure/imports with decisions and ownership records.
   Retain inconsistent/poor boundaries, rather than approving the majority pattern.
9. **Documentation conventions:** read accepted location/format/metadata/naming/ID
   rules and compare actual docs. If absent, use the generic contract defaults.
10. **Runtime context:** assemble sources/tests/docs, stack, persistence, folder
    ownership, boundaries, terms, canonical authorities, protected files, gates,
    effective overrides and evidence/provenance. Retain UNKNOWN/CONFLICT explicitly.
11. **Execute:** proceed with UPDATE/AUDIT/REPAIR/FULL_SYNC and the requested scope.

The context helper returns file/manifest candidates and unresolved dimensions.
It cannot approve prose or judge architecture; the agent MUST complete semantic
reading. Discovery never executes target build hooks. Keep context in run output by
default and re-discover changed areas when switching targets/revisions. Configuration
is optional evidence to reconcile, never a replacement for discovery.
