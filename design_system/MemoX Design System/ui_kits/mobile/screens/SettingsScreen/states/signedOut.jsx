/* Settings · state: signedOut — no account yet; the row invites sign-in. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Settings = R.Settings || {});
D.signedOut = function () {
  return { loading: false, account: { icon: 'log-in', iconBg: 'var(--memox-surface-container)', iconColor: 'var(--memox-on-surface-variant)', label: 'Sign in & sync', subtitle: 'Save your progress across devices', chip: null } };
};
})();
