/* MemoX Mobile v3 — CardExportScreen  (A12 · Card export)  ADDED in v3
   ────────────────────────────────────────────────────────────────────────
   A bottom sheet over the card list, in v1's sheet language (grabber · title ·
   option rows · footer buttons). Product rules it carries:
     scope = whole deck (ignores filter/search, BR-174) or the current selection;
     formats CSV (default) · TSV · XLSX; exactly six content columns, never
     schedule or history (BR-175); the file is handed to the system share
     mechanism and is never called "saved" (BR-181); dismissing the share sheet
     is a cancel, not an error; a stale selection fails as a whole; an empty
     scope is refused; export keeps the selection (BR-178).
   States: wholeDeck · selection · generating · shared · dismissed · failed ·
   shareUnavailable · staleSelection · emptyScope */
(function () {
const { StatusBar, Ic, Breadcrumb, OptionRow, Note, Snackbar, Scrim, BottomSheet, Spinner } = window;

const rows = [
  { front: 'reservation', back: 'sự đặt chỗ trước', st: 'reviewing' },
  { front: 'bill', back: 'hóa đơn', st: 'beginning' },
  { front: 'tip', back: 'tiền boa', st: 'new' },
  { front: 'menu', back: 'thực đơn', st: 'mastered' }
];
const TOKEN = { new: 'var(--memox-status-new)', beginning: 'var(--memox-status-learning)', reviewing: 'var(--memox-status-reviewing)', mastered: 'var(--memox-status-mastered)' };

/* Dimmed card list behind the sheet — a quiet stand-in for FlashcardList. */
function Backdrop({ selecting }) {
  return (
    <>
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" aria-label={selecting ? 'Clear selection' : 'Back'}><Ic name={selecting ? 'x' : 'arrow-left'} size="sm" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, minWidth: 0, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{selecting ? '12 selected' : 'Nhà hàng'}</div>
        {!selecting && <button className="icon-btn" aria-label="Deck actions"><Ic name="more-vertical" size="sm" color="var(--memox-on-surface-variant)" /></button>}
      </div>
      {!selecting && <Breadcrumb segments={[{ label: 'Library' }, { label: 'Tiếng Anh giao tiếp hằng ngày' }, { label: 'Nhà hàng' }]} />}
      <div className="scroll">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 4px 8px' }}>
          <span className="ov">{selecting ? '12 of 64 selected' : 'Showing 4 of 64'}</span>
        </div>
        {rows.map((c, i) =>
          <div key={c.front} style={{ marginBottom: 8, padding: '12px 12px', display: 'grid', gridTemplateColumns: selecting ? '22px 1fr' : '8px 1fr', gap: 12, alignItems: 'flex-start', background: 'var(--memox-surface-container-lowest)', border: selecting && i < 2 ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)', borderRadius: 12 }}>
            {selecting ?
              <span style={{ marginTop: 2, width: 20, height: 20, borderRadius: 'var(--memox-radius-xs)', boxSizing: 'border-box', border: i < 2 ? 'none' : '2px solid var(--memox-outline)', background: i < 2 ? 'var(--memox-primary)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{i < 2 && <Ic name="check" size={14} color="var(--memox-on-primary)" />}</span> :
              <div style={{ paddingTop: 4 }}><span className="status-dot" style={{ background: TOKEN[c.st], width: 8, height: 8 }} /></div>}
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.25 }}>{c.front}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4 }}>{c.back}</div>
            </div>
          </div>)}
      </div>
    </>);
}

const FORMATS = [
  { id: 'csv', t: 'CSV', s: 'Comma-separated · opens anywhere' },
  { id: 'tsv', t: 'TSV', s: 'Tab-separated · safest for commas in text' },
  { id: 'xlsx', t: 'XLSX', s: 'Excel workbook' }
];

function Sheet({ scope, count, generating = false, format = 'csv', problem = null }) {
  const title = scope === 'selection' ? `Export ${count} selected cards` : `Export all ${count} cards`;
  return (
    <BottomSheet scrim={false}>
      <div style={{ padding: '4px 20px 8px' }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>{title}</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.5 }}>
          {scope === 'selection' ? 'Only the cards you selected.' : 'Every card in Nhà hàng, whatever filter or search is active.'}
        </div>
      </div>
      {problem ?
        <div style={{ margin: '4px 20px 12px', padding: '12px 16px', background: problem.tone === 'warn' ? 'var(--memox-warning-soft)' : 'var(--memox-danger-soft)', border: `1px solid ${problem.tone === 'warn' ? 'var(--memox-warning-border)' : 'var(--memox-danger-border)'}`, borderRadius: 12, display: 'flex', gap: 8, alignItems: 'flex-start' }}>
          <Ic name={problem.icon} size="xs" color={problem.tone === 'warn' ? 'var(--memox-warning)' : 'var(--memox-error)'} />
          <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55 }}>
            <div style={{ fontWeight: 700, marginBottom: 2 }}>{problem.title}</div>
            <div style={{ color: 'var(--memox-on-surface-variant)' }}>{problem.body}</div>
          </div>
        </div> : null}
      <div className="ov" style={{ padding: '4px 20px 4px' }}>Format</div>
      <div style={{ padding: '0 4px' }}>
        {FORMATS.map((f, i) => <OptionRow key={f.id} title={f.t} sub={f.s} selected={format === f.id} disabled={generating} last={i === FORMATS.length - 1} />)}
      </div>
      <div style={{ padding: '4px 20px 8px' }}>
        <Note icon="file-text">Six columns: front, back, example, hint, pronunciation, tags. No schedule, no history — this is content, not a backup.</Note>
      </div>
      <div style={{ padding: '8px 16px 16px', display: 'flex', gap: 8, borderTop: 'var(--memox-border-ghost)' }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>{problem && problem.final ? 'Close' : 'Cancel'}</button>
        {!(problem && problem.final) &&
          <button className="pill-btn primary" disabled={generating} style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8, opacity: generating ? 0.7 : 1 }}>
            {generating ? <><Spinner color="var(--memox-on-primary)" size="xs" /> Preparing…</> : problem ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" /> Try again</> : <><Ic name="share-2" size="xs" color="var(--memox-on-primary)" /> Export and share</>}
          </button>}
      </div>
    </BottomSheet>);
}

function CardExportScreenV3({ go, state = 'wholeDeck' }) {
  const selecting = ['selection', 'staleSelection', 'shared', 'dismissed'].includes(state);
  const count = selecting ? 12 : 64;
  const scope = selecting ? 'selection' : 'deck';
  let overlay = null;
  switch (state) {
    case 'generating': overlay = <><Scrim /><Sheet scope={scope} count={count} generating /></>; break;
    case 'shared': overlay = <Snackbar>Handed 12 cards to the system as nha-hang-2026-09-16.csv</Snackbar>; break;
    case 'dismissed': overlay = null; break;
    case 'failed': overlay = <><Scrim /><Sheet scope={scope} count={count} problem={{ icon: 'alert-circle', title: 'Couldn’t prepare the file', body: 'Nothing was shared. Your cards are unchanged — try again.', tone: 'error' }} /></>; break;
    case 'shareUnavailable': overlay = <><Scrim /><Sheet scope={scope} count={count} problem={{ icon: 'share-2', title: 'No app on this device can receive a file', body: 'Install a file manager, drive or mail app, then export again.', tone: 'warn', final: true }} /></>; break;
    case 'staleSelection': overlay = <><Scrim /><Sheet scope={scope} count={count} problem={{ icon: 'alert-circle', title: 'A selected card is no longer in this deck', body: 'It was moved or sent to Trash meanwhile. Nothing was exported. Refresh the selection and export again.', tone: 'warn', final: true }} /></>; break;
    case 'emptyScope': overlay = <><Scrim /><Sheet scope="deck" count={0} problem={{ icon: 'copy', title: 'There is nothing to export', body: 'This deck has no cards. Add or import cards first.', tone: 'warn', final: true }} /></>; break;
    default: overlay = <><Scrim /><Sheet scope={scope} count={count} /></>;
  }
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <Backdrop selecting={selecting} />
      {overlay}
    </div>);
}

Object.assign(window, { CardExportScreenV3 });
})();
