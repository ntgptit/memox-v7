/* StudyResult · state: reset — invalidated · scheduler_reset / stale_generation: the deck was reset while the session was open (BR-84). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.reset = (ctx) => <>
  {ctx.Hero({ kind: 'reviewing', deck: 'Động từ · 동사', tone: 'ended', title: 'Ended by a reset', body: 'Learning progress of this deck was reset while you were studying, so this session could not continue. Answers given before the reset stay in the history of the earlier cycle.' })}
  {ctx.Facts({ kind: 'reviewing', finished: 5, answered: 5, wrong: 0, total: 5 })}
</>;
})();
