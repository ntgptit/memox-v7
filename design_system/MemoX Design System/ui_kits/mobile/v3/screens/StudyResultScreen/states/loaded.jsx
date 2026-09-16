/* StudyResult · state: loaded — review session completed. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.loaded = (ctx) => <>
  {ctx.Hero({ kind: 'reviewing', deck: 'Động từ · 동사', title: 'Review finished', body: <>You reviewed <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>20 cards</strong>. Their next due dates are set.</>, stats: [{ v: 20, l: 'Reviewed' }, { v: 20, l: 'Answered' }, { v: '3 / 23', l: 'Wrong' }] })}
  {ctx.Facts({ kind: 'reviewing', finished: 20, answered: 20, wrong: 3, total: 23 })}
</>;
})();
