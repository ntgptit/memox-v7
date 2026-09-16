/* Progress · state: loading — per-card skeletons. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.loading = function () { return { range: 'week', loading: true, allEmpty: false, insufficient: false, partial: false, error: false }; };
})();
