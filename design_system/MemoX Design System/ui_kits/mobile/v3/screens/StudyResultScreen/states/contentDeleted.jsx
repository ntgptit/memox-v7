/* StudyResult · state: contentDeleted — invalidated · content_deleted: the deck or one of its cards went to Trash mid-session (BR-259). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyResult = R.StudyResult || {});
D.contentDeleted = (ctx) => <>
  {ctx.Hero({ kind: 'reviewing', deck: 'Trạng từ · 부사', tone: 'ended', title: 'Ended — content moved to Trash', body: 'A card in this session was moved to Trash, so the session ended. Answers given before that are kept.' })}
  {ctx.Facts({ kind: 'reviewing', finished: 3, answered: 3, wrong: 0, total: 3 })}
  {ctx.EndNote({ icon: 'history', children: 'Restore the card from Trash to include it in the next review.' })}
</>;
})();
