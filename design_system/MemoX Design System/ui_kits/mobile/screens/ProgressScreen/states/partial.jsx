/* Progress · state: partial — one chart has data, another doesn't (accuracy empty). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.partial = function () { return { range: 'week', loading: false, allEmpty: false, insufficient: false, partial: true, error: false }; };
})();
