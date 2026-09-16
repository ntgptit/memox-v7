/* LibraryOverview · state: search — search bar focused (styled by the shell),
   populated folder list behind it. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});
D.search = function (ctx) { return { body: ctx.FoldersList() }; };
})();
