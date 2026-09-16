/* AccountSync · state: signingIn — Google sign-in in progress. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.signingIn = function () { return { branch: 'out', isLoading: true, isFailed: false }; };
})();
