/* Progress · state: loaded — populated week range. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.loaded = function () { return { range: 'week', loading: false, allEmpty: false, insufficient: false, partial: false, error: false }; };
})();
