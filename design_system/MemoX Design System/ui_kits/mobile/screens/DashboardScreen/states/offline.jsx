/* Dashboard · state: offline
   Connectivity lost. Non-blocking offline banner on top; the rest behaves like
   the loaded day (local-first — everything still works). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.offline = function (ctx) {
  return (
    <>
      <ctx.OfflineBanner />
      {ctx.ContinueStudying()}
      {ctx.StreakGoal()}
      {ctx.PrimaryCTA({ hasDue: true })}
      {ctx.RecentDecks()}
    </>);
};
})();
