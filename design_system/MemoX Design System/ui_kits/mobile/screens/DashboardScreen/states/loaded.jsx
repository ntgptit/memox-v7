/* Dashboard · state: loaded
   Populated day — due cards, a resumable session, streak + goal on. The default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.loaded = function (ctx) {
  return (
    <>
      {ctx.ContinueStudying()}
      {ctx.StreakGoal()}
      {ctx.PrimaryCTA({ hasDue: true })}
      {ctx.RecentDecks()}
    </>);
};
})();
