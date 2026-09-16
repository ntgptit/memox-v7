/* Dashboard · state: error
   Today's-summary load failed. Inline error card on top; streak/goal + recent
   decks still render (they're independent of the summary fetch). Primary CTA is
   suppressed on error. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Dashboard = R.Dashboard || {});

D.error = function (ctx) {
  return (
    <>
      {ctx.ErrorCard()}
      {ctx.StreakGoal()}
      {ctx.RecentDecks()}
    </>);
};
})();
