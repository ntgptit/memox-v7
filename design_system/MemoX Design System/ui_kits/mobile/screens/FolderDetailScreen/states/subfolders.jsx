/* FolderDetail · state: subfolders — child-folder list, no decks. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FolderDetail = R.FolderDetail || {});
D.subfolders = function (ctx) { return { body: ctx.SubfolderList() }; };
})();
