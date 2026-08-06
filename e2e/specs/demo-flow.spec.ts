import { test, expect } from '@playwright/test';
import {
  openApp,
  reopenApp,
  tap,
  typeInto,
  expectVisible,
  expectGone,
  text,
} from './support/app';

/**
 * The demo flow M4.12 requires, driven through the real UI on Flutter Web.
 *
 * **One test, not ten.** Each step depends on what the last one wrote, and
 * splitting them would mean either re-driving the whole flow per test — minutes
 * of CanvasKit boot each — or seeding a database behind the UI's back, which is
 * exactly what this exists to avoid. A failure names the step in its assertion.
 *
 * Runs against the **staging** entrypoint, so the database starts empty: the
 * flow begins at "cold start with nothing in it", and the development flavor's
 * fixture seed would make that first assertion meaningless.
 */
test.describe('the deck and card flow', () => {
  test('a cold start ends with a three-level tree, a card, and both removed again', async ({
    page,
  }) => {
    await openApp(page);

    // ---- cold start, nothing in it -------------------------------------
    await expectVisible(page, 'No decks yet');

    // ---- create a root deck, choosing a scheduler (BR-11) --------------
    await tap(page, 'New deck');
    await typeInto(page, 'Deck name', 'Korean');
    // The scheduler is mandatory and has no default — a root deck cannot exist
    // without one, so this tap is part of creating it rather than a preference.
    await tap(page, 'Eight boxes');
    await tap(page, 'Create');

    await expectVisible(page, 'Korean');
    await expectGone(page, 'No decks yet');

    // ---- second level -------------------------------------------------
    await tap(page, 'Korean');
    // No "what are you adding?" step here: a root deck holds sub-decks only
    // (BR-58), so the only thing it can offer is the one it offers.
    await tap(page, 'New sub-deck');
    await typeInto(page, 'Deck name', 'Vocabulary');
    await tap(page, 'Create');
    await expectVisible(page, 'Vocabulary');

    // ---- third level, and it holds cards (BR-55, BR-62) ----------------
    // `Vocabulary` is `unset` — it has not been committed to sub-decks or cards
    // yet, so this is where the app asks.
    await tap(page, 'Vocabulary');
    await tap(page, 'Add to this deck');
    await tap(page, 'New sub-deck');
    await typeInto(page, 'Deck name', 'Food');
    await tap(page, 'Create');
    await expectVisible(page, 'Food');

    // ---- a card -------------------------------------------------------
    await tap(page, 'Food');
    await tap(page, 'Add to this deck');
    await tap(page, 'New card');
    await typeInto(page, 'Front', 'kimchi');
    await typeInto(page, 'Back', 'kim chi');
    await tap(page, 'Save card');

    await expectVisible(page, 'kimchi');

    // ---- edit it ------------------------------------------------------
    await tap(page, 'kimchi');
    await typeInto(page, 'Front', 'kimchi jjigae');
    await tap(page, 'Save changes');
    await expectVisible(page, 'kimchi jjigae');

    // ---- close and re-open: the data is still there --------------------
    // A reload is a genuine restart for this build — drift keeps the database
    // in IndexedDB, so nothing about the page survives except what was written.
    await reopenApp(page);
    await expectVisible(page, 'kimchi jjigae');

    // ---- delete the card ----------------------------------------------
    await tap(page, 'kimchi jjigae');
    await tap(page, 'Delete');
    await tap(page, 'Delete');
    await expectVisible(page, 'No cards yet');

    // ---- back to the root, by the breadcrumb ---------------------------
    // The breadcrumb rather than browser history: the app's own path control is
    // what a user has, and `goBack` walks a stack GoRouter also writes to, so
    // the number of steps is an implementation detail this should not encode.
    await tap(page, 'Root');
    await expectVisible(page, 'Korean');

    // ---- delete the deck ------------------------------------------------
    await tap(page, 'Deck actions');
    await tap(page, 'Delete');
    // The confirm names what goes with it (BR-04) before it is possible to
    // agree, which is why there are two taps and not one.
    await tap(page, 'Delete');

    await expectVisible(page, 'No decks yet');
  });
});
