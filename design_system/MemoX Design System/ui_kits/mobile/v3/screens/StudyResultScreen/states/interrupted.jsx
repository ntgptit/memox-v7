/* StudyResult · state: interrupted — abandoned · interrupted: the app was closed by the system and the session was not resumed the same day (BR-103). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.interrupted = (ctx) => <>
  {ctx.Hero({ kind: 'reviewing', deck: 'Động từ · 동사', tone: 'paused', title: 'Session interrupted', body: 'This session from yesterday was closed by the system and could not be resumed today. Every answer you gave is kept.', stats: [{ v: 7, l: 'Reviewed' }, { v: 7, l: 'Answered' }, { v: '1 / 8', l: 'Wrong' }] })}
  {ctx.Facts({ kind: 'reviewing', finished: 7, answered: 7, wrong: 1, total: 8 })}
</>;
})();
