/* CardDetail · state: loadMore — the first page of 50 is shown; more history is available (A10). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.CardDetail = R.CardDetail || {});
D.loadMore = (ctx) => (
  <>
    {ctx.GenHeader({ label: 'Cycle 2 · Eight boxes', sub: 'since reset on 19 Aug' })}
    {ctx.Timeline(ctx.events)}
    <button className="pill-btn" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', border: 'none', marginBottom: 12 }}>
      Load older history
    </button>
  </>);
})();
