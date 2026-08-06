import { test } from '@playwright/test';
import { openApp, tap, typeInto, expectVisible } from './support/app';

/**
 * The second scheduler, and the content-type lock the deck tree is built on
 * (BR-62, BR-68).
 *
 * Separate from the demo flow because it asks a different question: that one
 * asks whether the whole path works, these ask whether a deck commits to one
 * kind of child and can be let go of again.
 */
test.describe('content type and the sm2 scheduler', () => {
  test('a deck that took a card keeps taking only cards', async ({ page }) => {
    await openApp(page);

    // **`SM-2`, not `Eight boxes`.** The two schedulers have different action
    // sets (BR-30) and different review-state columns (BR-09); a suite that only
    // ever creates `eight_box` decks proves half the app.
    await tap(page, 'New deck');
    await typeInto(page, 'Deck name', 'Grammar');
    await tap(page, 'SM-2');
    await tap(page, 'Create');
    await expectVisible(page, 'Grammar');

    await tap(page, 'Grammar');
    await tap(page, 'New sub-deck');
    await typeInto(page, 'Deck name', 'Particles');
    await tap(page, 'Create');
    // The sub-deck carries the root's scheduler rather than one of its own
    // (BR-06), and the row says so.
    await expectVisible(page, 'SM-2');

    // `Particles` is `unset`: it takes either kind, and the first child decides.
    await tap(page, 'Particles');
    await tap(page, 'Add to this deck');
    await tap(page, 'New card');
    await typeInto(page, 'Front', '은/는');
    await typeInto(page, 'Back', 'topic marker');
    await tap(page, 'Save card');
    await expectVisible(page, '은/는');

    // Emptying it does not undo the lock (BR-68). A card deck opens straight
    // into its card list, which offers "Add card" and nothing about sub-decks —
    // the lock is visible as the absence of a choice.
    await tap(page, '은/는');
    await tap(page, 'Delete');
    await tap(page, 'Delete');
    await expectVisible(page, 'No cards yet');
    await expectVisible(page, 'Add card');
  });

  test('an emptied deck can be allowed both kinds again (BR-68)', async ({
    page,
  }) => {
    await openApp(page);

    await tap(page, 'New deck');
    await typeInto(page, 'Deck name', 'Reading');
    await tap(page, 'Eight boxes');
    await tap(page, 'Create');

    await tap(page, 'Reading');
    await tap(page, 'New sub-deck');
    await typeInto(page, 'Deck name', 'Passages');
    await tap(page, 'Create');

    // `Passages` locks to `deck` the moment it takes a sub-deck.
    await tap(page, 'Passages');
    await tap(page, 'Add to this deck');
    await tap(page, 'New sub-deck');
    await typeInto(page, 'Deck name', 'Short');
    await tap(page, 'Create');
    await expectVisible(page, 'Short');

    // Empty it again. The lock survives, which is the rule being tested.
    await tap(page, 'Deck actions');
    await tap(page, 'Delete');
    await tap(page, 'Delete');
    await expectVisible(page, 'No sub-decks yet');

    // **The reset is offered from inside the deck, not from its row above.**
    // Whether a deck may be reset is a question about its own children, and the
    // level above cannot see them — `deck_list_screen.dart` passes
    // `mayOfferReset: false` there on purpose.
    await tap(page, 'Deck actions');
    await tap(page, 'Allow cards or decks again');
    await tap(page, 'Allow both');

    // Back to asking, which is what `unset` means.
    await tap(page, 'Add to this deck');
    await expectVisible(page, 'New card');
  });
});
