/* Settings · state: signingIn — sign-in in progress (spinner subtitle). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Settings = R.Settings || {});
D.signingIn = function (ctx) {
  const { Spinner } = ctx;
  return { loading: false, account: { icon: 'user-circle', iconBg: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', iconColor: 'var(--memox-primary)', label: 'Account & sync', subtitle: <><Spinner size="xs" /> Signing in…</>, chip: null } };
};
})();
