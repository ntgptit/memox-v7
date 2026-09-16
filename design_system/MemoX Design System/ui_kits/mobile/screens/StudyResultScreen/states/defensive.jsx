/* StudyResult · state: defensive
   Session ended with no graded answers → paused hero + reassurance note only;
   the analytical cards are skipped. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});

D.defensive = function (ctx) {
  const result = ctx.makeResult({ defensive: true });
  return (
    <>
      {ctx.Hero({ result, defensive: true })}
      {ctx.DefensiveNote()}
    </>);
};
})();
