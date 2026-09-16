/* LibraryOverview · state: overflow — folder kebab/long-press opens the action
   sheet over the populated list. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});
D.overflow = function (ctx) {
  return { body: ctx.FoldersList(), overlay: <><ctx.Scrim />{ctx.OverflowSheet()}</> };
};
})();
