/* CardDetail · state: loaded — all history loaded: the current cycle, then the earlier SM-2 cycle, each group named in text (BR-243). Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.CardDetail = R.CardDetail || {});
D.loaded = (ctx) => (
  <>
    {ctx.GenHeader({ label: 'Cycle 2 · Eight boxes', sub: 'since reset on 19 Aug' })}
    {ctx.Timeline(ctx.events)}
    {ctx.GenHeader({ label: 'Cycle 1 · SM-2', sub: 'before reset' })}
    {ctx.Timeline(ctx.olderEvents, { end: true })}
  </>);
})();
