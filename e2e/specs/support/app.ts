import { expect, type Page, type Locator } from '@playwright/test';

/**
 * Driving the Flutter Web build from Playwright.
 *
 * **Everything goes through the semantics tree, and the app holds it open.**
 * Flutter Web paints to a canvas — without semantics the DOM holds one element
 * and Playwright can see nothing. The engine ships a hidden
 * `<flt-semantics-placeholder>` button that turns the tree on, and clicking it
 * is the usual trick; it does not survive here. The engine switches back to raw
 * pointer handling as soon as it sees ordinary pointer events, so the tree
 * vanished the moment the suite tapped anything — which reads as "the deck was
 * never created" while the deck is plainly on screen.
 *
 * The build this runs against therefore calls `ensureSemantics()` at startup,
 * behind `--dart-define=MEMOX_E2E=true` (see `bootstrap.dart`). A shipped build
 * has that branch compiled out.
 *
 * Once on, widgets appear as `<flt-semantics>` nodes: a button carries
 * `role="button"` and its label as text, a `TextField` becomes a real
 * `<textarea data-semantics-role="text-field">` with the field label as its
 * `aria-label`, and the app-bar title becomes an `<h2>`.
 *
 * **This is also why every control in the app needs a semantic label.** A
 * control the screen reader cannot name is a control this suite cannot reach —
 * the accessibility work and the E2E reach are the same work.
 */

/** How long to give CanvasKit, the database and the first frame. */
const bootTimeout = 60_000;

/**
 * Loads the app and waits until it is interactive.
 *
 * `reload` re-enters through the same path, which is what "close and re-open
 * the app" means on the web — drift keeps its data in IndexedDB, so a reload is
 * a real persistence check rather than a page-level one.
 */
export async function openApp(page: Page): Promise<void> {
  await page.goto('/', { waitUntil: 'load' });
  await waitForApp(page);
}

export async function reopenApp(page: Page): Promise<void> {
  await page.reload({ waitUntil: 'load' });
  await waitForApp(page);
}

/**
 * Waits until the shell has painted and published itself.
 *
 * The app bar is up as soon as the shell mounts, before any deck read resolves,
 * so this means "the app is running" rather than "the app has data".
 */
async function waitForApp(page: Page): Promise<void> {
  await expect(page.locator('flt-semantics').first()).toBeAttached({
    timeout: bootTimeout,
  });
  await expect(page.locator('h2').first()).toBeVisible({ timeout: bootTimeout });
}

/**
 * A tappable control carrying [label].
 *
 * **`[flt-tappable]`, not `[role="button"]`.** The engine stamps that attribute
 * on every node with a tap action, whatever ARIA role it ends up with — the
 * scheduler choices are radios and a card row is a plain container, neither of
 * which is a `button`. Selecting on the role reached the app-bar actions and
 * nothing else.
 *
 * **Two selectors, because a label reaches the DOM in two different ways.** A
 * plain button carries its label as text; anything the app gave a `Semantics`
 * label — the scheduler radios among them — carries it as `aria-label` and has
 * no text at all, so matching on text alone silently misses exactly the
 * controls accessibility work has already been done on.
 */
export function button(page: Page, label: string): Locator {
  return page.locator(
    `flt-semantics[flt-tappable][aria-label*="${label}"], ` +
      `flt-semantics[flt-tappable]:has-text("${label}")`,
  );
}

/**
 * Taps [label].
 *
 * **`.last()`, not `.first()`.** A label often appears twice — the app-bar
 * action and the empty state both say "New deck", and a sheet opening over a
 * screen keeps the screen's own nodes in the tree. The last match is the most
 * recently painted one, which is the one on top and the one a finger would hit.
 */
export async function tap(page: Page, label: string): Promise<void> {
  await tapNth(page, label, -1);
}

/**
 * Taps the [index]-th control carrying [label]; negative counts from the end.
 *
 * Needed where the same label appears on a row and in the chrome above it — a
 * deck list shows "Deck actions" once per row *and* once in the app bar for the
 * deck being looked at, and those two open different menus over the same
 * screen.
 */
export async function tapNth(
  page: Page,
  label: string,
  index: number,
): Promise<void> {
  const all = button(page, label);
  const target = index < 0 ? all.last() : all.nth(index);
  await target.waitFor({ state: 'visible' });
  await target.click();
}

/**
 * A text field by the label the app gives it.
 *
 * **Substring, not exact.** A field with both a label and a hint publishes them
 * as one `aria-label` — the card editor's front side is `"Front
The term you
 * want to remember"`, while the deck form's is just `"Deck name"`. An exact
 * match found the second and not the first.
 */
export function field(page: Page, label: string): Locator {
  return page.locator(
    `textarea[aria-label*="${label}"], input[aria-label*="${label}"]`,
  );
}

export async function typeInto(
  page: Page,
  label: string,
  value: string,
): Promise<void> {
  const target = field(page, label).last();
  await target.waitFor({ state: 'visible' });
  await target.click();
  await target.fill(value);
  // Flutter reads the DOM field on input events; giving it a frame before the
  // next tap avoids submitting a form the framework has not seen typed into.
  await page.waitForTimeout(250);
}

/**
 * Any rendered text — a plain span, a button label, or a merged row.
 *
 * **Same two selectors as [button], and for the same reason.** A deck row
 * merges its name, its meta line and its due state into one node whose whole
 * content is the `aria-label`; its `textContent` is empty. Matching on text
 * alone found the empty state and the section headings and missed every row the
 * app actually renders, which reads as "the deck was never created" while the
 * deck is on screen.
 */
export function text(page: Page, value: string): Locator {
  return page.locator(
    `flt-semantics[aria-label*="${value}"], flt-semantics:has-text("${value}")`,
  );
}

export async function expectVisible(page: Page, value: string): Promise<void> {
  await expect(text(page, value).last()).toBeVisible();
}

export async function expectGone(page: Page, value: string): Promise<void> {
  await expect(text(page, value)).toHaveCount(0);
}
