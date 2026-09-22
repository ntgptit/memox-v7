# verification document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# Verification

## Scope and prerequisites
<Supported environments, required setup, inputs/fixtures and excluded checks.>

## Commands and expected results
| Check | Working directory | Exact command/procedure | Prerequisites | Expected result | Authority |
|---|---|---|---|---|---|
| <check> | <repo-relative location> | <verified command> | <setup> | <observable result> | <CI/script/instruction> |

## Business coverage
| BR/UC | Condition/branch | Test or manual procedure | Expected outcome | Coverage gap |
|---|---|---|---|---|
| <links> | <scenario> | <test name + locator> | <business result> | <gap or NONE> |

## Manual verification
### <Procedure>
Setup: <state and inputs>.
Steps: <ordered user actions>.
Expected: <observable outcomes including failure branches>.
Cleanup: <necessary restoration or NONE with reason>.

## Execution record
| Check | Revision/dirty state | Environment | Command | Actual result | Evidence |
|---|---|---|---|---|---|
| <check> | <actual context> | <runtime> | <executed command> | <PASS/FAIL/NOT RUN> | <log/result locator> |

## Limitations and unresolved checks
<Skipped/unavailable checks, reasons, affected claims and next action. Test existence is not a passing execution.>
```
