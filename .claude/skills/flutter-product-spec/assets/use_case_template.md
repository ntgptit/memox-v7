# Use cases

Each use case gets an ID (`UC-01`) that tests, WBS tasks and commit messages cite.

---

## UC-01 · <name>

**Actor:** <who>
**Trigger:** <what starts it — user action, schedule, push, app launch>
**Preconditions:**
- <what must already be true; auth state, existing data, connectivity>

**Main flow:**
1.
2.
3.

**Alternative flows:**
- **A1 — <condition>:** <steps, and where it rejoins the main flow>

**Error flows:**
- **E1 — <failure>:** <what the user sees, what recovery is offered, what state
  the system is left in>

Cover at minimum, where they apply: no network, request timeout, server 4xx,
server 5xx, validation rejection, permission denied, resource missing, conflict
with a concurrent change.

**Postconditions:**
- <what is true afterward — this is what the integration test asserts>

**Business rules referenced:** BR-xx, BR-yy

**UI states implied:** initial · loading · loaded · empty · error · refreshing · submitting
<Cross out any that genuinely cannot occur, and say why. An unlisted state is a
state nobody will build.>

---

## UC-02 · <name>

...
