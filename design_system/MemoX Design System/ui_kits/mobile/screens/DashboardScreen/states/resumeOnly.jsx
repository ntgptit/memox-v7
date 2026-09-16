/* Dashboard · state: resumeOnly
   A resumable session exists but nothing is due → CTA shows "all caught up". */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.resumeOnly = function (ctx) {
  return (
    <>
      {ctx.ContinueStudying()}
      {ctx.StreakGoal()}
      {ctx.PrimaryCTA({ hasDue: false })}
      {ctx.RecentDecks()}
    </>);
};
})();
