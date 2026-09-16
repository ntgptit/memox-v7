/* Progress · state: never — never studied — a new user, distinguished from a lapsed one (hasLifetimeActivity). Replaces v1 empty/insufficient. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.never = () => ({ range: 'week', never: true });
})();
