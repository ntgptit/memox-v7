/* LibraryOverview · state: loaded — populated root-folder list. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});
D.loaded = function (ctx) { return { body: ctx.FoldersList() }; };
})();
