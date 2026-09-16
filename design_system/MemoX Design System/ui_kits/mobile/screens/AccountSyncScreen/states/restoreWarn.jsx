/* AccountSync · state: restoreWarn — backup is from a different device; warn before restore. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.restoreWarn = function () { return { branch: 'in', uploading: false, restoring: false, restoreWarn: true, noBackup: false, tokenExpired: false }; };
})();
