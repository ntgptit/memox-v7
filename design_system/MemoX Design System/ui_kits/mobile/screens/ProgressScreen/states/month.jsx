/* Progress · state: month — populated month range. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.month = function () { return { range: 'month', loading: false, allEmpty: false, insufficient: false, partial: false, error: false }; };
})();
