/* FolderDetail · state: decks — deck list (default content mode). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FolderDetail = R.FolderDetail || {});
D.decks = function (ctx) { return { body: ctx.DeckList() }; };
})();
