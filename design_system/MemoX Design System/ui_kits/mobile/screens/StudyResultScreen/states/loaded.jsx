/* StudyResult · state: loaded
   Normal end-of-session summary. The default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});

D.loaded = function (ctx) {
  const result = ctx.makeResult({});
  return (
    <>
      {ctx.Hero({ result })}
      {ctx.Breakdown({ result })}
      {ctx.BoxChanges({ result })}
      {ctx.StreakGoal()}
      {ctx.ToughCards({ result })}
    </>);
};
})();
