/* StudyResult · state: saveError — failed · persistence_error: an answer could not be saved and the session could not go on (BR-157). Replaces v1 finFailed. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.saveError = (ctx) => <>
  {ctx.Hero({ kind: 'reviewing', deck: 'Động từ · 동사', tone: 'error', title: 'Stopped by a save error', body: 'An answer could not be written to this device, so the session stopped. Everything saved before that is kept; the unanswered cards are still due.' })}
  {ctx.Facts({ kind: 'reviewing', finished: 11, answered: 11, wrong: 2, total: 13 })}
</>;
})();
