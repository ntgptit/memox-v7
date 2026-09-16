/* Settings · state: populated — signed in, synced. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Settings = R.Settings || {});
D.populated = function () {
  return { loading: false, account: { icon: 'user-circle', iconBg: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', iconColor: 'var(--memox-primary)', label: 'Account & sync', subtitle: 'alex@memox.app · synced 2 min ago', chip: null } };
};
})();
