/* StudyResult · state: goalOff
   Daily goal disabled → omit the streak/goal block. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});

D.goalOff = function (ctx) {
  const result = ctx.makeResult({});
  return (
    <>
      {ctx.Hero({ result })}
      {ctx.Breakdown({ result })}
      {ctx.BoxChanges({ result })}
      {ctx.ToughCards({ result })}
    </>);
};
})();
