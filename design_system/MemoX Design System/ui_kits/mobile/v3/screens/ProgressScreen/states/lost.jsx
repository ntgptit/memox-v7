/* Progress · state: lost — streak lost — no activity yesterday or today (0). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.lost = () => ({ range: 'week', lostStreak: true });
})();
