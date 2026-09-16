/* StudyResult · state: finFailed
   Finalization save failed → warning banner under the hero. Done still works
   (footer copy adjusts in the main shell). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});

D.finFailed = function (ctx) {
  const result = ctx.makeResult({});
  return (
    <>
      {ctx.Hero({ result })}
      {ctx.FinFailedBanner()}
      {ctx.Breakdown({ result })}
      {ctx.BoxChanges({ result })}
      {ctx.StreakGoal()}
      {ctx.ToughCards({ result })}
    </>);
};
})();
