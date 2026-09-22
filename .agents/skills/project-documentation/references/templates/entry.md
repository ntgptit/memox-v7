# entry document template

Read [template rules](template-rules.md) before using this scaffold.
MUST fill the following file scaffold from discovered evidence and applicable authorities.

Insert the shared document identity block after the output title, unless the local
metadata format already carries it. The fenced content is the output scaffold,
not a prewritten claim about any repository.

```markdown
# <Project name>

## Purpose
<What the project does, for whom, and the outcome it provides. Link the product authority.>

## Prerequisites
| Requirement | Supported value/version | How to obtain or verify | Evidence |
|---|---|---|---|
| <actual prerequisite> | <supported value> | <command or canonical guide> | <locator> |

## Quick start
1. <Prepare inputs/environment using verified instructions.>
2. <Run the supported entry command or perform the first user action.>
3. <Observable successful result and where to go next.>

## Documentation and reading order
| Order | Document | Answers | Authority/status |
|---|---|---|---|
| <order> | <relative link to each applicable canonical file> | <reader question> | <status> |

## Verification
<Exact verification entry command or linked canonical verification procedure; distinguish instructions from executed results.>

## Limitations and support
<Known usage constraints; existing troubleshooting/support entry if available; unresolved onboarding gaps.>
```
