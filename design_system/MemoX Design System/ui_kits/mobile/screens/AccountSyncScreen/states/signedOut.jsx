/* AccountSync · state: signedOut — not linked; hero + sign-in CTA. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.signedOut = function () { return { branch: 'out', isLoading: false, isFailed: false }; };
})();
