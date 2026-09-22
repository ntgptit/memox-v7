# Optional repository overrides

Read `.agents/project-documentation.json` at ROOT when present. Missing config means
generic defaults plus discovery. `--config PATH` explicitly selects another JSON file
(relative to ROOT). Keep config outside the skill payload so updates preserve it.

A present file requires `schema_version: 1`. Supply only necessary delta keys:

| Key | Default | Meaning |
|---|---|---|
| context_files | [] | Extra instructions/conventions/terminology authorities to read |
| source_roots, test_roots, documentation_roots | [] | Root hints added to discovered candidates, not a replacement scan |
| exclude_globs | [] | Explicit inventory exclusions, visible in context |
| required_files | [] | Locally required documents |
| canonical_locations | {} | Knowledge type to authoritative path/section |
| document_rules | [] | glob, optional header_fields and required_headings |
| checks | [] | name, argv list, read_only flag |
| pin | {} | Expected active version and/or digest and/or source_id |

Lists replace empty defaults; dictionaries merge by key. Unknown keys/invalid types
or paths escaping ROOT fail fast. Paths are repository-relative, independent of
installation scope. Overrides carry CONFIGURED provenance and their source. Higher
instructions outrank config; contradictions remain CONFLICT before dependent writes.

Example of a small delta, not a mandatory scaffold:

```json
{"schema_version":1,"context_files":["CONTRIBUTING.md"],"required_files":["README.md"]}
```

Inspect configured command authority before `--run-checks`. `{python}` in argv resolves
to the current interpreter. Commands run from ROOT without a shell. `--audit` skips
commands not marked read-only and reports incomplete coverage; that label itself
is not proof of no side effects. Metadata rules supplement local semantic review and
existing guards. Domain/product facts belong in referenced docs, not this config.
