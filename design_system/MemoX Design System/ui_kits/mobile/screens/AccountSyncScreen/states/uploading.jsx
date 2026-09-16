/* AccountSync · state: uploading — upload to Drive in progress. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.uploading = function () { return { branch: 'in', uploading: true, restoring: false, restoreWarn: false, noBackup: false, tokenExpired: false }; };
})();
