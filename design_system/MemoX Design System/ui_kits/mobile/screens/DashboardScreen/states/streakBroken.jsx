/* Dashboard · state: streakBroken
   One-time gentle banner: streak reset to 0. Streak card hides itself at 0,
   goal ring resets (completedToday 0). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.streakBroken = function (ctx) {
  return (
    <>
      {ctx.StreakBrokenBanner()}
      {ctx.ContinueStudying()}
      {ctx.StreakGoal({ streak: 0, completedToday: 0 })}
      {ctx.PrimaryCTA({ hasDue: true })}
      {ctx.RecentDecks()}
    </>);
};
})();
