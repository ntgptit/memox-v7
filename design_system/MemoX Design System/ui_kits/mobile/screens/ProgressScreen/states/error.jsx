/* Progress · state: error — aggregate load failed (full-screen error layout). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.error = function () { return { range: 'week', loading: false, allEmpty: false, insufficient: false, partial: false, error: true }; };
})();
