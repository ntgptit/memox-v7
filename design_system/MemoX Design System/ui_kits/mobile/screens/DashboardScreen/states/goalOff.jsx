/* Dashboard · state: goalOff
   Daily goal disabled → hide the goal ring, no nudging. Streak still shows. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.goalOff = function (ctx) {
  return (
    <>
      {ctx.ContinueStudying()}
      {ctx.StreakGoal({ showGoal: false })}
      {ctx.PrimaryCTA({ hasDue: true })}
      {ctx.RecentDecks()}
    </>);
};
})();
