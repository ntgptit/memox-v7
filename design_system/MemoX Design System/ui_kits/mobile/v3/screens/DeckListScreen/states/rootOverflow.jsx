/* LibraryOverview · state: overflow — deck ⋮ opens the action sheet over the populated list. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootOverflow = function (ctx) {
  return { body: ctx.DeckList(), overlay: <><ctx.Scrim />{ctx.OverflowSheet()}</> };
};
})();
