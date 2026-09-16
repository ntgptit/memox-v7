/* StudyResult · state: learning — learning session completed: cards finished the stage sequence and are due tomorrow (BR-144). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.learning = (ctx) => <>
  {ctx.Hero({ kind: 'learning', deck: 'Nhà hàng', title: 'Learning finished', body: <><strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>12 cards</strong> finished learning. They come back tomorrow at 00:00.</>, stats: [{ v: 12, l: 'Learned' }, { v: 12, l: 'Answered' }, { v: '5 / 53', l: 'Wrong' }] })}
  {ctx.Facts({ kind: 'learning', finished: 12, answered: 12, wrong: 5, total: 53 })}
</>;
})();
