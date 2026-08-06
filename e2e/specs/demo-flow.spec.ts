import { execFileSync } from 'node:child_process';
import { test } from '@playwright/test';
import {
  openApp,
  reopenApp,
  tap,
  typeInto,
  expectVisible,
  expectGone,
} from './support/app';
import { step, writeEvidenceReport } from './support/evidence';

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
 *
 * **Each step is also recorded.** M4.12 asks for a demo-flow report with
 * step-by-step evidence; `step()` captures the screen after each one and
 * `writeEvidenceReport` writes `e2e/report/demo-flow.md` at the end. The
 * assertions are the test — the capture only records what was there when they
 * passed.
 */
test.describe('the deck and card flow', () => {
  test('a cold start ends with a three-level tree, a card, and both removed again', async ({
    page,
  }, testInfo) => {
    await openApp(page);

    await step(page, 'Cold start', 'The app opens on an empty database', async () => {
      await expectVisible(page, 'No decks yet');
    });

    await step(
      page,
      'Create a root deck with a scheduler',
      'BR-11 — a root deck cannot exist without a study mode',
      async () => {
        await tap(page, 'New deck');
        await typeInto(page, 'Deck name', 'Korean');
        // The scheduler is mandatory and has no default, so this tap is part of
        // creating the deck rather than a preference.
        await tap(page, 'Eight boxes');
        await tap(page, 'Create');
        await expectVisible(page, 'Korean');
        await expectGone(page, 'No decks yet');
      },
    );

    await step(
      page,
      'Add a second level',
      'BR-58 — a root holds sub-decks only, so it offers nothing to choose',
      async () => {
        await tap(page, 'Korean');
        await tap(page, 'New sub-deck');
        await typeInto(page, 'Deck name', 'Vocabulary');
        await tap(page, 'Create');
        await expectVisible(page, 'Vocabulary');
      },
    );

    await step(
      page,
      'Add a third level',
      'BR-55, BR-62 — an `unset` deck asks which kind of child it takes',
      async () => {
        await tap(page, 'Vocabulary');
        await tap(page, 'Add to this deck');
        await tap(page, 'New sub-deck');
        await typeInto(page, 'Deck name', 'Food');
        await tap(page, 'Create');
        await expectVisible(page, 'Food');
      },
    );

    await step(
      page,
      'Create a card',
      'UC-04 — the first card locks its deck to `card`',
      async () => {
        await tap(page, 'Food');
        await tap(page, 'Add to this deck');
        await tap(page, 'New card');
        await typeInto(page, 'Front', 'kimchi');
        await typeInto(page, 'Back', 'kim chi');
        await tap(page, 'Save card');
        await expectVisible(page, 'kimchi');
      },
    );

    await step(
      page,
      'Edit the card',
      'BR-10 — editing content leaves the review state alone',
      async () => {
        await tap(page, 'kimchi');
        await typeInto(page, 'Front', 'kimchi jjigae');
        await tap(page, 'Save changes');
        await expectVisible(page, 'kimchi jjigae');
      },
    );

    await step(
      page,
      'Close and re-open the app',
      'Persistence — a reload is a genuine restart; the database is IndexedDB',
      async () => {
        await reopenApp(page);
        await expectVisible(page, 'kimchi jjigae');
      },
    );

    await step(
      page,
      'Delete the card',
      'BR-67 — the deck keeps its content type when its last card goes',
      async () => {
        await tap(page, 'kimchi jjigae');
        await tap(page, 'Delete');
        await tap(page, 'Delete');
        await expectVisible(page, 'No cards yet');
      },
    );

    await step(
      page,
      'Return to the root by the breadcrumb',
      "UC-06 — the app's own path control, not browser history",
      async () => {
        await tap(page, 'Root');
        await expectVisible(page, 'Korean');
      },
    );

    await step(
      page,
      'Delete the deck',
      'BR-04 — the confirm names what goes with it before agreeing is possible',
      async () => {
        await tap(page, 'Deck actions');
        await tap(page, 'Delete');
        await tap(page, 'Delete');
        await expectVisible(page, 'No decks yet');
      },
    );

    const viewport = page.viewportSize();
    writeEvidenceReport({
      // `git` rather than an env var: the report has to name the build it
      // describes, and CI's SHA variable is absent on a developer machine —
      // where this report is most often read.
      // `execFileSync` with an argument array: no shell, so nothing here can
      // be interpreted as one.
      commit: execFileSync('git', ['rev-parse', '--short', 'HEAD'])
        .toString()
        .trim(),
      viewport: viewport ? `${viewport.width}x${viewport.height}` : 'unknown',
    });
    testInfo.annotations.push({
      type: 'evidence',
      description: 'e2e/report/demo-flow.md',
    });
  });
});
