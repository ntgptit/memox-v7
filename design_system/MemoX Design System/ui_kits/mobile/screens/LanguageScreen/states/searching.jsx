/* Language · state: searching — filtered list while typing a query. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Language = R.Language || {});
D.searching = function () { return { searching: true, changed: false }; };
})();
