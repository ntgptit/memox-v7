/* MemoX v2 · A11 — Card import
   A short flow: where from → how the columns map → what will happen → done.
   Every row's fate is visible before anything is written, the whole import is
   one all-or-nothing write (BR-171), and imported cards arrive new, with no
   schedule and no history. */
(function () {
const { Ic, StatusBar, ScreenScroll, BottomBar, Spinner, Toggle } = window;
const { useT, Note } = window;

const ROWS = [
  { n: 2, status: 'ready', front: '학교', back: 'trường học' },
  { n: 3, status: 'duplicateExisting', front: '가다', back: 'đi' },
  { n: 4, status: 'invalid', front: '', back: 'không có mặt trước', why: { en: 'Front is empty', vi: 'Mặt trước để trống' } },
  { n: 5, status: 'duplicateInFile', front: '학교', back: 'Trường học' },
  { n: 6, status: 'blank', front: '', back: '' },
  { n: 7, status: 'invalid', front: '-기 때문에 / -아서/어서 / -(으)니까: ba cách nói “vì … nên” khác nhau về sắc thái', back: 'vì … nên', why: { en: 'Front is 27 characters over the 60 limit', vi: 'Mặt trước vượt giới hạn 60 ký tự 27 ký tự' } },
  { n: 8, status: 'invalid', front: '읽다', back: 'đọc', why: { en: 'More than 10 tags in the tags cell', vi: 'Ô nhãn có hơn 10 nhãn' } },
  { n: 9, status: 'ready', front: '쓰다', back: 'viết; dùng; đội (mũ)' }
];
const STATUS = {
  ready: { en: 'Ready', vi: 'Sẵn sàng', c: 'var(--memox-status-mastered)' },
  duplicateExisting: { en: 'Already in this deck', vi: 'Đã có trong bộ', c: 'var(--memox-text-secondary)' },
  duplicateInFile: { en: 'Repeated in the file', vi: 'Lặp trong tệp', c: 'var(--memox-text-secondary)' },
  invalid: { en: 'Cannot be imported', vi: 'Không nhập được', c: 'var(--memox-warning-ink)' },
  blank: { en: 'Empty row', vi: 'Dòng trống', c: 'var(--memox-text-secondary)' }
};
const COLUMNS = [
  { head: 'term', field: 'front' },
  { head: 'meaning', field: 'back' },
  { head: 'sentence', field: 'example' },
  { head: 'labels', field: 'tags' },
  { head: 'level', field: null }
];
const FIELD = { front: { en: 'Front', vi: 'Mặt trước' }, back: { en: 'Back', vi: 'Mặt sau' }, example: { en: 'Example', vi: 'Ví dụ' }, tags: { en: 'Tags', vi: 'Nhãn' }, hint: { en: 'Hint', vi: 'Gợi ý' } };

function Step({ n, of, label }) {
  return (
    <div style={{ padding: '0 16px 12px', display: 'flex', alignItems: 'center', gap: 8 }}>
      <span style={{ fontSize: 11, fontWeight: 800, letterSpacing: 0.8, textTransform: 'uppercase', color: 'var(--memox-text-secondary)' }}>
        {label} · {n}/{of}
      </span>
      <span style={{ flex: 1, display: 'flex', gap: 4 }}>
        {[1, 2, 3].map((i) =>
          <span key={i} style={{ flex: 1, height: 3, borderRadius: 999, background: i <= n ? 'var(--memox-primary)' : 'var(--memox-surface-container)' }} />)}
      </span>
    </div>);
}

function RowItem({ r }) {
  const t = useT();
  const s = STATUS[r.status];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '26px 1fr', gap: 10, padding: '10px 2px', borderBottom: 'var(--memox-border-ghost)' }}>
      <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums', paddingTop: 2 }}>{r.n}</span>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, lineHeight: 1.35, wordBreak: 'break-word', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden', opacity: r.status === 'blank' ? 0.5 : 1 }}>
          {r.front || t('(no front)', '(không có mặt trước)')}
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {r.back || '—'}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 5, fontSize: 11, fontWeight: 700, color: s.c }}>
          <span className="status-dot" style={{ width: 6, height: 6, background: s.c }} />
          {t(s.en, s.vi)}
          {r.why ? <span style={{ fontWeight: 500, color: 'var(--memox-text-secondary)' }}>· {t(r.why.en, r.why.vi)}</span> : null}
        </div>
      </div>
    </div>);
}

function CardImport({ state = 'source' }) {
  const t = useT();
  const done = ['completed', 'completedWithSkips', 'noCardsAdded', 'commitFailure'].includes(state);
  const preview = ['preview', 'previewSkipDupes', 'submitting'].includes(state);
  const mapping = ['mapping', 'mappingIncomplete'].includes(state);
  const stepNo = done ? 3 : preview ? 3 : mapping ? 2 : 1;

  let body;
  if (state === 'source') body =
    <>
      <div style={{ display: 'grid', gap: 10 }}>
        {[
          { ic: 'file-spreadsheet', en: 'Choose a file', vi: 'Chọn tệp', sen: 'CSV, TSV or XLSX', svi: 'CSV, TSV hoặc XLSX' },
          { ic: 'clipboard-paste', en: 'Paste text', vi: 'Dán văn bản', sen: 'One card per line, columns separated by tabs or commas', svi: 'Mỗi dòng một thẻ, các cột cách nhau bằng tab hoặc dấu phẩy' }
        ].map((o) =>
          <button key={o.en} className="card" style={{ padding: 16, display: 'grid', gridTemplateColumns: '36px 1fr 20px', gap: 12, alignItems: 'center', textAlign: 'left', border: 'none', cursor: 'pointer' }}>
            <span className="icon-tile" style={{ width: 36, height: 36, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name={o.ic} size="sm" color="var(--memox-primary)" />
            </span>
            <span>
              <span style={{ display: 'block', fontSize: 14.5, fontWeight: 700 }}>{t(o.en, o.vi)}</span>
              <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 3, lineHeight: 1.45 }}>{t(o.sen, o.svi)}</span>
            </span>
            <Ic name="chevron-right" size="sm" color="var(--memox-text-secondary)" />
          </button>)}
      </div>
      <Note icon="info" style={{ marginTop: 14 }}>
        {t('Files must be UTF-8. Everything you import stays on this device — nothing is uploaded.', 'Tệp phải ở dạng UTF-8. Mọi thứ bạn nhập đều nằm trên máy này — không có gì được tải lên.')}
      </Note>
    </>;
  else if (state === 'parsing') body =
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, padding: '90px 0' }}>
      <Spinner size="md" />
      <div style={{ fontSize: 13.5, color: 'var(--memox-text-secondary)' }}>{t('Reading topik-nouns.xlsx…', 'Đang đọc topik-nouns.xlsx…')}</div>
    </div>;
  else if (['encoding', 'unsupported', 'emptySheet'].includes(state)) {
    const msg = {
      encoding: t('This file is saved as UTF-16. Re-save it as UTF-8 (in most spreadsheet apps: “CSV UTF-8”) and try again.', 'Tệp này lưu ở dạng UTF-16. Hãy lưu lại thành UTF-8 (trong phần mềm bảng tính thường là “CSV UTF-8”) rồi thử lại.'),
      unsupported: t('MemoX reads CSV, TSV and XLSX. A .numbers file has to be exported first.', 'MemoX đọc CSV, TSV và XLSX. Tệp .numbers cần được xuất ra trước.'),
      emptySheet: t('The first sheet of this workbook has no rows. Pick a file with the cards in its first sheet.', 'Sheet đầu tiên của tệp không có dòng nào. Hãy chọn tệp có thẻ ở sheet đầu.')
    }[state];
    body =
      <>
        <Note icon="alert-circle" tone="warning">{msg}</Note>
        <button className="pill-btn outline" style={{ width: '100%', marginTop: 14 }}>{t('Choose another file', 'Chọn tệp khác')}</button>
      </>;
  }
  else if (mapping) body =
    <>
      <div className="card" style={{ padding: '14px 16px', marginBottom: 12, display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center' }}>
        <span>
          <span style={{ display: 'block', fontSize: 14, fontWeight: 700 }}>{t('First row is a header', 'Dòng đầu là tiêu đề')}</span>
          <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 3 }}>term, meaning, sentence, labels, level</span>
        </span>
        <Toggle on />
      </div>
      <div className="card" style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
        <span className="ov" style={{ fontSize: 11 }}>{t('Columns', 'Các cột')}</span>
        {COLUMNS.map((col, i) => {
          const missing = state === 'mappingIncomplete' && col.field === 'back';
          return (
            <div key={col.head} style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 10, alignItems: 'center', padding: '8px 0', borderBottom: i < COLUMNS.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
              <span style={{ minWidth: 0 }}>
                <span style={{ display: 'block', fontSize: 13.5, fontWeight: 600 }}>{col.head}</span>
                <span style={{ display: 'block', fontSize: 11.5, color: 'var(--memox-text-secondary)', marginTop: 1 }}>학교 · 가다 · 읽다</span>
              </span>
              <span className="pill-btn" style={{
                height: 34, padding: '0 10px', fontSize: 12.5, fontWeight: 700, gap: 4,
                background: missing ? 'var(--memox-danger-soft)' : col.field ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container)',
                color: missing ? 'var(--memox-error)' : col.field ? 'var(--memox-primary)' : 'var(--memox-text-secondary)'
              }}>
                {missing ? t('Not mapped', 'Chưa gán') : col.field ? t(FIELD[col.field].en, FIELD[col.field].vi) : t('Skip', 'Bỏ qua')}
                <Ic name="chevron-down" size="xs" color={missing ? 'var(--memox-error)' : col.field ? 'var(--memox-primary)' : 'var(--memox-text-secondary)'} />
              </span>
            </div>);
        })}
      </div>
      {state === 'mappingIncomplete' ?
        <Note icon="alert-circle" tone="warning" style={{ marginTop: 12 }}>
          {t('A card needs a front and a back, so both have to come from a column before you can continue.', 'Một thẻ cần mặt trước và mặt sau, nên cả hai phải được gán từ một cột trước khi tiếp tục.')}
        </Note> :
        <Note style={{ marginTop: 12 }}>
          {t('Tags in one cell are separated by a semicolon: 명사;TOPIK I', 'Nhiều nhãn trong một ô cách nhau bằng dấu chấm phẩy: 명사;TOPIK I')}
        </Note>}
    </>;
  else if (preview) body =
    <>
      <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '4px 12px', marginBottom: 12, fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>
        {[
          { l: t('ready', 'sẵn sàng'), v: 2, c: 'var(--memox-mastery)' },
          { l: t('duplicates', 'trùng'), v: 2, c: 'var(--memox-on-surface-variant)' },
          { l: t('cannot be imported', 'không nhập được'), v: 3, c: 'var(--memox-warning)' },
          { l: t('empty rows', 'dòng trống'), v: 1, c: 'var(--memox-outline)' }
        ].map((b) =>
          <span key={b.l} style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <span className="status-dot" style={{ width: 6, height: 6, background: b.c }} />
            {b.l} <span style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{b.v}</span>
          </span>)}
      </div>
      <div className="card" style={{ padding: '14px 16px', marginBottom: 12, display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center' }}>
        <span>
          <span style={{ display: 'block', fontSize: 14, fontWeight: 700 }}>{t('Import duplicates too', 'Nhập cả thẻ trùng')}</span>
          <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 3, lineHeight: 1.45 }}>
            {t('A duplicate has the same front and back as a card already in this deck, or as an earlier row.', 'Thẻ trùng là thẻ có mặt trước và mặt sau giống thẻ đã có trong bộ, hoặc giống dòng phía trên.')}
          </span>
        </span>
        <Toggle on={state === 'preview'} />
      </div>
      <div className="card" style={{ padding: 16 }}>
        <span className="ov" style={{ fontSize: 11 }}>{t('All 8 rows', 'Cả 8 dòng')}</span>
        <div style={{ marginTop: 8 }}>{ROWS.map((r) => <RowItem key={r.n} r={r} />)}</div>
      </div>
    </>;
  else if (state === 'targetRejects') body =
    <>
      <Note icon="alert-circle" tone="warning">
        {t('This deck started holding sub-decks while you were setting the import up, so it can no longer take cards. Nothing was imported.', 'Bộ này đã bắt đầu chứa bộ con trong lúc bạn chuẩn bị nhập, nên không nhận thẻ được nữa. Chưa nhập gì cả.')}
      </Note>
      <button className="pill-btn outline" style={{ width: '100%', marginTop: 14 }}>{t('Choose another deck', 'Chọn bộ khác')}</button>
    </>;
  else {
    const c = {
      completed: { ic: 'check', tone: 'ok', head: t('1,500 cards imported', 'Đã nhập 1.500 thẻ'), body: t('They are in Động từ · 동사 as new cards, with no schedule yet. Learn them whenever you like.', 'Các thẻ đã vào Động từ · 동사 dưới dạng thẻ mới, chưa có lịch ôn. Bạn có thể học lúc nào cũng được.') },
      completedWithSkips: { ic: 'check', tone: 'ok', head: t('2 cards imported, 6 rows skipped', 'Đã nhập 2 thẻ, bỏ qua 6 dòng'), body: t('2 rows were already in this deck, 3 could not be imported and 1 was empty. The 2 new cards are in the deck.', '2 dòng đã có trong bộ, 3 dòng không nhập được và 1 dòng trống. 2 thẻ mới đã vào bộ.') },
      noCardsAdded: { ic: 'info', tone: 'note', head: t('No cards were added', 'Không thẻ nào được thêm'), body: t('Every row in the file is already in this deck, so there was nothing new to import. Your deck is unchanged.', 'Mọi dòng trong tệp đều đã có trong bộ nên không có gì mới để nhập. Bộ thẻ của bạn không thay đổi.') },
      commitFailure: { ic: 'alert-circle', tone: 'danger', head: t('The import failed', 'Nhập thất bại'), body: t('Nothing was written — not one card. The deck is exactly as it was, and you can try the same file again.', 'Chưa ghi gì cả — không một thẻ nào. Bộ thẻ vẫn như trước và bạn có thể thử lại cùng tệp đó.') }
    }[state];
    body =
      <div style={{ paddingTop: 10 }}>
        <div className="card" style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 12, alignItems: 'center', textAlign: 'center' }}>
          <span style={{
            width: 48, height: 48, borderRadius: 16, display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: c.tone === 'danger' ? 'var(--memox-danger-soft)' : c.tone === 'ok' ? 'var(--memox-success-soft)' : 'var(--memox-surface-container)'
          }}>
            <Ic name={c.ic} size="md" color={c.tone === 'danger' ? 'var(--memox-error)' : c.tone === 'ok' ? 'var(--memox-success)' : 'var(--memox-text-secondary)'} />
          </span>
          <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.2px' }}>{c.head}</div>
          <div style={{ fontSize: 13.5, lineHeight: 1.55, color: 'var(--memox-text-secondary)' }}>{c.body}</div>
        </div>
      </div>;
  }

  const footer = state === 'source' || state === 'parsing' ? null :
    done ?
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button className="pill-btn primary" style={{ width: '100%' }}>{t('Back to the deck', 'Về bộ thẻ')}</button>
        {state === 'commitFailure' &&
          <button className="pill-btn" style={{ width: '100%', background: 'transparent', color: 'var(--memox-primary)', fontWeight: 700 }}>{t('Try the import again', 'Thử nhập lại')}</button>}
      </div> :
      <div style={{ display: 'flex', gap: 8 }}>
        <button className="pill-btn" style={{ flex: '0 0 96px', background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)' }}>{t('Back', 'Quay lại')}</button>
        <button className="pill-btn primary" style={{ flex: 1, gap: 6 }} disabled={state === 'mappingIncomplete' || state === 'targetRejects'}>
          {state === 'submitting' ? <Spinner color="var(--memox-on-primary)" /> : null}
          {state === 'submitting' ? t('Importing…', 'Đang nhập…')
            : preview ? t(state === 'preview' ? 'Import 4 cards' : 'Import 2 cards', state === 'preview' ? 'Nhập 4 thẻ' : 'Nhập 2 thẻ')
              : t('Preview rows', 'Xem trước các dòng')}
        </button>
      </div>;

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" aria-label={t('Cancel', 'Huỷ')}><Ic name="x" size="md" /></button>
        <div className="title">{t('Import cards', 'Nhập thẻ')}</div>
      </div>
      <div style={{ padding: '0 16px 10px', fontSize: 12, color: 'var(--memox-text-secondary)' }}>
        {t('Into', 'Vào')} <strong style={{ fontWeight: 700, color: 'var(--memox-text-primary)' }}>Động từ · 동사</strong>
      </div>
      {!done && <Step n={stepNo} of={3} label={stepNo === 1 ? t('Source', 'Nguồn') : stepNo === 2 ? t('Columns', 'Các cột') : t('Review', 'Kiểm tra')} />}
      <ScreenScroll>{body}</ScreenScroll>
      {footer ? <BottomBar>{footer}</BottomBar> : null}
    </div>);
}

Object.assign(window, { CardImport });
})();
