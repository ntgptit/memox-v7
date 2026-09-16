/* StudyResult · state: toughEmpty
   No tough cards from this session → the calm "nothing to revisit" tough card. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});

D.toughEmpty = function (ctx) {
  const result = ctx.makeResult({ toughEmpty: true });
  return (
    <>
      {ctx.Hero({ result })}
      {ctx.Breakdown({ result })}
      {ctx.BoxChanges({ result })}
      {ctx.StreakGoal()}
      {ctx.ToughCards({ result, toughEmpty: true })}
    </>);
};
})();
