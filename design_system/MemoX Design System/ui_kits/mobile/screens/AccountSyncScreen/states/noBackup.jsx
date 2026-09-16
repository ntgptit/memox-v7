/* AccountSync · state: noBackup — signed in, no Drive backup yet. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.noBackup = function () { return { branch: 'in', uploading: false, restoring: false, restoreWarn: false, noBackup: true, tokenExpired: false }; };
})();
