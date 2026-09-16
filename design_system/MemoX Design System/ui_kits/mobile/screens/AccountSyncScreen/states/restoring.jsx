/* AccountSync · state: restoring — restore in progress (snapshot step). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.restoring = function () { return { branch: 'in', uploading: false, restoring: true, restoreWarn: false, noBackup: false, tokenExpired: false }; };
})();
