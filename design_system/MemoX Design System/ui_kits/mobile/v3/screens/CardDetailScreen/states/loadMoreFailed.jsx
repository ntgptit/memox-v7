/* CardDetail · state: loadMoreFailed — loading the next page failed; what is shown stays, retry offered. ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.CardDetail = R.CardDetail || {});
D.loadMoreFailed = (ctx) => {
  const { Ic } = ctx;
  return (
    <>
      {ctx.GenHeader({ label: 'Cycle 2 · Eight boxes', sub: 'since reset on 19 Aug' })}
      {ctx.Timeline(ctx.events)}
      <div style={{ padding: '8px 12px', background: 'var(--memox-danger-soft)', border: '1px solid var(--memox-danger-border)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'center', fontSize: 12, lineHeight: 1.45 }}>
        <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
        <span style={{ flex: 1 }}><strong style={{ fontWeight: 700 }}>Couldn’t load older history.</strong> <span style={{ color: 'var(--memox-on-surface-variant)' }}>What is shown is complete up to here.</span></span>
        <button className="pill-btn primary" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-sm)', fontSize: 12 }}>Retry</button>
      </div>
    </>);
};
})();
