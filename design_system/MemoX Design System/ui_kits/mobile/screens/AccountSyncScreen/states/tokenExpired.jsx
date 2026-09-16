/* AccountSync · state: tokenExpired — Drive access token expired; re-auth prompt. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.tokenExpired = function () { return { branch: 'in', uploading: false, restoring: false, restoreWarn: false, noBackup: false, tokenExpired: true }; };
})();
