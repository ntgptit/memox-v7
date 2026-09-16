/* Progress · state: empty — no study data at all (each chart shows its own empty). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.empty = function () { return { range: 'week', loading: false, allEmpty: true, insufficient: false, partial: false, error: false }; };
})();
