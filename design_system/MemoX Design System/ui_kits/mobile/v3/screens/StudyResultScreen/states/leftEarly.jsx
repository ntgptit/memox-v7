/* StudyResult · state: leftEarly — abandoned · user_exit: everything answered is kept (BR-86); unfinished learning cards get no schedule (BR-144). Replaces v1 "defensive". */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.leftEarly = (ctx) => <>
  {ctx.Hero({ kind: 'learning', deck: 'Nhà hàng', tone: 'paused', title: 'You left early', body: 'The 4 cards you finished are kept. The other 8 stay new and will be offered again.', stats: [{ v: 4, l: 'Learned' }, { v: 9, l: 'Answered' }, { v: '2 / 14', l: 'Wrong' }] })}
  {ctx.Facts({ kind: 'learning', finished: 4, answered: 9, wrong: 2, total: 14 })}
</>;
})();
