/* StudyResult · state: schedulerChanged — invalidated · scheduler_changed: the review algorithm was changed while the session was open (BR-14). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.schedulerChanged = (ctx) => <>
  {ctx.Hero({ kind: 'learning', deck: 'IT', tone: 'ended', title: 'Ended by an algorithm change', body: 'The deck switched to a different review algorithm, so its learning sequence changed. Every card is new again; start learning from the deck.' })}
  {ctx.EndNote({ icon: 'info', children: 'Nothing was lost — the answers are in the history.' })}
</>;
})();
