import { defineConfig } from '@playwright/test';

/**
 * Playwright against the Flutter Web build (AD-04).
 *
 * **A mobile viewport, not a desktop one.** Android is the release target and
 * the web build exists to exercise the same screens; running them at 1280 wide
 * would test a layout no user has. 390x844 is the size the card-list gutter and
 * filter-row measurements in `app_chip_theme.dart` were taken at, so a
 * regression there shows up here at the same numbers.
 *
 * **`channel: 'chrome'` rather than a downloaded browser.** The machine already
 * has Chrome, and Flutter Web's CanvasKit path is what ships to users on
 * Chromium — pulling a second binary buys nothing and makes a fresh clone need
 * a 150MB download before it can run one test.
 *
 * **The server is `build/web`, served statically.** `flutter run -d chrome`
 * would work too and is worse: it rebuilds on connect, so the first test waits
 * on a compile whose failures land in a different log than the test output.
 */
export default defineConfig({
  testDir: './specs',
  // Flutter Web boots CanvasKit, opens a database and settles a first frame
  // before anything is clickable. The default 30s is enough on a warm machine
  // and not on a cold one.
  timeout: 90_000,
  expect: { timeout: 15_000 },
  // Serial: every spec drives the same origin, and drift's storage is per
  // origin — two workers would share one database and race each other's decks.
  workers: 1,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['github'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL: 'http://127.0.0.1:5173',
    viewport: { width: 390, height: 844 },
    hasTouch: true,
    // The machine's own Chrome by default — it is already installed and it is
    // the engine the app ships to. CI has no Chrome, so it sets
    // PLAYWRIGHT_BROWSER_CHANNEL=chromium and uses the downloaded build.
    channel: process.env.PLAYWRIGHT_BROWSER_CHANNEL ?? 'chrome',
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  webServer: {
    // `--single` so a deep link falls back to index.html; GoRouter owns the
    // path once the app is up.
    command: 'npx --yes serve ../build/web --listen 5173 --single --no-clipboard',
    url: 'http://127.0.0.1:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
