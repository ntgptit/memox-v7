/* FlashcardList · state: empty — deck has zero cards — add or import (A8). v1 composition; "Anki" removed (CSV, TSV, XLSX or pasted text only). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.empty = function (ctx) {
  const { Ic, Note } = ctx;
  const body = (
    <div style={{ marginTop: 8 }}>
      <div className="card" style={{ padding: '32px 24px', textAlign: 'center', marginBottom: 16 }}>
        <div style={{ width: 64, height: 64, borderRadius: 20, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
          <Ic name="copy" size="lg" color="var(--memox-primary)" />
        </div>
        <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>No cards in this deck yet</div>
        <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
          Write your first card, or bring many at once from a spreadsheet or pasted text.
        </div>
      </div>
      <button className="pill-btn primary" style={{ width: '100%', height: 48, borderRadius: 12, fontSize: 14, marginBottom: 8 }}>
        <Ic name="plus" size="sm" color="var(--memox-on-primary)" />
        Add first card
      </button>
      <button className="pill-btn" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', border: 'none', gap: 8 }}>
        <Ic name="upload" size="xs" color="var(--memox-primary)" />
        Import cards (CSV, TSV, XLSX, text)
      </button>
      <Note style={{ marginTop: 16 }}>Studying this deck becomes available once it holds at least one card.</Note>
    </div>);
  return { body };
};
})();
