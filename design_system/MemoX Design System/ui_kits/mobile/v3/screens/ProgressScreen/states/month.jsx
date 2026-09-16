/* Progress · state: month — 30-day range (instant switch, same read). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.month = () => ({ range: 'month' });
})();
