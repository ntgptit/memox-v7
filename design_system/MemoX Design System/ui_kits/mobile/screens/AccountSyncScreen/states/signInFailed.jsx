/* AccountSync · state: signInFailed — sign-in failed; danger banner over the hero. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.signInFailed = function () { return { branch: 'out', isLoading: false, isFailed: true }; };
})();
