/* Settings · state: syncError — last sync failed; a Retry chip on the Account row. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Settings = R.Settings || {});
D.syncError = function (ctx) {
  const { Ic } = ctx;
  const chip = (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, height: 24, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', fontSize: 12, fontWeight: 600 }}>
      <Ic name="cloud-off" size="xs" color="var(--memox-streak)" />
      Retry
    </span>);
  return { loading: false, account: { icon: 'user-circle', iconBg: 'color-mix(in srgb, var(--memox-streak) 10%, transparent)', iconColor: 'var(--memox-streak)', label: 'Account & sync', subtitle: 'alex@memox.app · last synced 2 days ago', chip } };
};
})();
