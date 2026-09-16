/* AccountSync · state: ready — signed in, backup matches local. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.AccountSync = R.AccountSync || {});
D.ready = function () { return { branch: 'in', uploading: false, restoring: false, restoreWarn: false, noBackup: false, tokenExpired: false }; };
})();
