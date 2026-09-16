/* Progress · state: insufficient — some data, not enough for a trend yet. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.insufficient = function () { return { range: 'week', loading: false, allEmpty: false, insufficient: true, partial: false, error: false }; };
})();
