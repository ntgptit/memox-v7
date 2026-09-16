/* Dashboard · state: multiResume
   Multiple paused sessions → the resume card grows a "3 other paused sessions"
   chip that opens a picker sheet. Otherwise identical to loaded. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.multiResume = function (ctx) {
  return (
    <>
      {ctx.ContinueStudying({ multiResume: true })}
      {ctx.StreakGoal()}
      {ctx.PrimaryCTA({ hasDue: true })}
      {ctx.RecentDecks()}
    </>);
};
})();
