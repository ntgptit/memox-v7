/* StudyResult · state: large — a 200-card review session, the maximum (BR-24). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.large = (ctx) => <>
  {ctx.Hero({ kind: 'reviewing', deck: 'IELTS Academic Word List', title: 'Review finished', body: <>You reviewed <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>200 cards</strong> — the session limit.</>, stats: [{ v: 200, l: 'Reviewed' }, { v: 200, l: 'Answered' }, { v: '41 / 241', l: 'Wrong' }] })}
  {ctx.Facts({ kind: 'reviewing', finished: 200, answered: 200, wrong: 41, total: 241 })}
</>;
})();
