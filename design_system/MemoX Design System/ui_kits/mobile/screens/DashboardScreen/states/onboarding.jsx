/* Dashboard · state: onboarding
   Zero content — no decks, no cards. Hero CTA + reassurance points only.
   (App-bar greeting switches to "Welcome to MemoX" in the shell.) */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.onboarding = function (ctx) {
  return ctx.Onboarding();
};
})();
