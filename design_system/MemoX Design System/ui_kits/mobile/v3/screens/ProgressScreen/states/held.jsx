/* Progress · state: held — nothing studied yet today, streak held from yesterday (BR-197). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.held = () => ({ range: 'week', heldStreak: true });
})();
