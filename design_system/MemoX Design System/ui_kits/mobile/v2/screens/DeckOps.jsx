/* MemoX v2 · A2–A4 — Deck create, rename, move, reorder, delete
   All of these happen over the tree, so they are dialogs and sheets on top of
   the level the user is already looking at. A new root deck needs an explicit
   review-schedule choice (BR-11); a move lists every candidate with the reason
   it cannot take the deck (BR-70, BR-74); deleting is worded as moving to Trash
   and carries no destructive emphasis (BR-256, BR-266). */
(function () {
const { Ic, BottomSheet, Dialog, Spinner, TextField } = window;
const { useT, FieldLabel, Note, SheetHead, ConfirmDialog, Snackbar, schedLabel } = window;

const SCHEDULES = [
  { id: 'eight_box', en: 'Eight boxes', vi: 'Tám hộp', sen: 'A card moves up one box when remembered and back to the first when forgotten. Forgiving after a long break.', svi: 'Nhớ được thì lên một hộp, quên thì về hộp đầu. Dễ quay lại sau thời gian dài nghỉ.' },
  { id: 'sm2', en: 'SM-2', vi: 'SM-2', sen: 'Intervals stretch or shrink with how well you recall each card. Fewer reviews for what you know.', svi: 'Khoảng cách ôn giãn ra hoặc co lại theo mức bạn nhớ từng thẻ. Ôn ít hơn với thẻ đã nhớ.' }
];

const TARGETS = [
  { name: '한국어 TOPIK I · Từ vựng', depth: 1, ok: true },
  { name: 'Danh từ · 명사', depth: 2, ok: true },
  { name: 'Danh từ · 명사 / Gia đình', depth: 3, ok: true },
  { name: 'Động từ · 동사', depth: 2, ok: false, why: { en: 'Holds cards', vi: 'Đang chứa thẻ' } },
  { name: 'Tính từ · 형용사', depth: 2, ok: true },
  { name: 'Danh từ · 명사 / Thức ăn', depth: 3, ok: false, why: { en: 'Already the parent', vi: 'Vốn là bộ cha' } },
  { name: 'Tiếng Anh giao tiếp hằng ngày', depth: 1, ok: false, why: { en: 'Different review schedule (Eight boxes)', vi: 'Lịch ôn khác (Tám hộp)' } },
  { name: 'Level 9 · 아홉', depth: 9, ok: false, why: { en: 'Would pass level 10', vi: 'Sẽ vượt mức 10' } }
];

function OptionCard({ selected, title, sub, onClick }) {
  return (
    <button type="button" onClick={onClick} style={{
      width: '100%', display: 'grid', gridTemplateColumns: '20px 1fr', gap: 10, alignItems: 'start', textAlign: 'left',
      padding: 12, borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', color: 'var(--memox-on-surface)',
      background: selected ? 'var(--memox-primary-soft)' : 'var(--memox-surface-container-low)',
      border: selected ? '1px solid var(--memox-primary-border)' : '1px solid transparent'
    }}>
      <span style={{ width: 18, height: 18, borderRadius: 999, marginTop: 2, border: selected ? '5px solid var(--memox-primary)' : '2px solid var(--memox-outline)' }} />
      <span style={{ minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 14, fontWeight: 700 }}>{title}</span>
        <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 3, lineHeight: 1.45 }}>{sub}</span>
      </span>
    </button>);
}

function DeckOps({ state = 'createRoot' }) {
  const t = useT();
  const Bg = window.LibraryDeckList;
  const bgState = ['createSub', 'rename', 'move', 'moveNone', 'moveRefused', 'reorder', 'delete', 'deleting', 'undoRefused'].includes(state) ? 'inside' : 'topLevel';

  const nameErr = state === 'nameEmpty' ? t('A name is needed.', 'Cần có tên.')
    : state === 'nameTooLong' ? t('7 characters over the 200 limit.', 'Vượt giới hạn 200 ký tự 7 ký tự.') : undefined;
  const longName = 'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi chứng chỉ quốc tế: kế toán, kiểm toán, thị trường chứng khoán, bảo hiểm và cụm từ thường gặp trong báo cáo thường niên của doanh nghiệp niêm yết';

  let overlay = null;

  if (['createRoot', 'nameEmpty', 'nameTooLong', 'algoMissing', 'submitting'].includes(state)) {
    const chosen = ['createRoot', 'nameEmpty', 'nameTooLong', 'submitting'].includes(state) ? 'sm2' : null;
    overlay =
      <Dialog>
        <div style={{ padding: '20px 20px 4px' }}>
          <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.3px', marginBottom: 14 }}>{t('New deck', 'Bộ thẻ mới')}</div>
          <FieldLabel len={state === 'nameEmpty' ? 0 : state === 'nameTooLong' ? 207 : 12} max={200} error={!!nameErr}>
            {t('NAME', 'TÊN')}
          </FieldLabel>
          <TextField focused value={state === 'nameEmpty' ? '' : state === 'nameTooLong' ? longName : 'Korean verbs'}
            placeholder={t('e.g. Korean verbs', 'ví dụ: Động từ tiếng Hàn')} error={nameErr} multiline={state === 'nameTooLong'} />
          <div style={{ marginTop: 18, marginBottom: 8 }}>
            <FieldLabel>{t('REVIEW SCHEDULE', 'LỊCH ÔN TẬP')}</FieldLabel>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {SCHEDULES.map((s) => <OptionCard key={s.id} selected={chosen === s.id} title={t(s.en, s.vi)} sub={t(s.sen, s.svi)} />)}
            </div>
            {state === 'algoMissing' &&
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8, fontSize: 12, color: 'var(--memox-error)' }}>
                <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
                {t('Choose one — there is no default.', 'Hãy chọn một — không có lựa chọn mặc định.')}
              </div>}
          </div>
          <Note icon="lock" style={{ marginTop: 6 }}>
            {t('The schedule can be changed until the first card in this deck finishes learning. After that, only a reset can change it.', 'Bạn có thể đổi lịch ôn cho tới khi thẻ đầu tiên trong bộ học xong. Sau đó chỉ việc đặt lại tiến trình mới đổi được.')}
          </Note>
        </div>
        <div style={{ display: 'flex', gap: 8, padding: '14px 16px 16px', justifyContent: 'flex-end' }}>
          <button className="pill-btn" style={{ background: 'transparent', color: 'var(--memox-text-secondary)', fontWeight: 700 }}>{t('Cancel', 'Huỷ')}</button>
          <button className="pill-btn primary" disabled={!!nameErr || state === 'algoMissing'} style={{ gap: 6 }}>
            {state === 'submitting' ? <Spinner color="var(--memox-on-primary)" /> : null}
            {state === 'submitting' ? t('Creating…', 'Đang tạo…') : t('Create deck', 'Tạo bộ thẻ')}
          </button>
        </div>
      </Dialog>;
  }

  if (state === 'createSub' || state === 'parentHoldsCards' || state === 'maxDepth') {
    overlay =
      <Dialog>
        <div style={{ padding: '20px 20px 4px' }}>
          <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.3px' }}>{t('New sub-deck', 'Bộ con mới')}</div>
          <div style={{ fontSize: 12.5, color: 'var(--memox-text-secondary)', marginTop: 4, marginBottom: 14 }}>
            {t('Inside', 'Bên trong')} <strong style={{ color: 'var(--memox-text-primary)' }}>한국어 TOPIK I · Từ vựng</strong>
          </div>
          {state === 'parentHoldsCards' ?
            <Note icon="alert-circle" tone="warning">
              {t('This deck now holds cards, so it cannot also hold sub-decks. Move its cards into a new sub-deck first, or pick another deck.', 'Bộ này hiện chứa thẻ nên không thể chứa thêm bộ con. Hãy chuyển thẻ vào một bộ con trước, hoặc chọn bộ khác.')}
            </Note> :
            state === 'maxDepth' ?
              <Note icon="alert-circle" tone="warning">
                {t('This deck is already at level 10, the deepest MemoX allows. Nothing can be created inside it.', 'Bộ này đã ở mức 10, mức sâu nhất MemoX cho phép. Không thể tạo thêm bên trong.')}
              </Note> :
              <>
                <FieldLabel len={9} max={200}>{t('NAME', 'TÊN')}</FieldLabel>
                <TextField focused value="Phó từ" />
              </>}
        </div>
        <div style={{ display: 'flex', gap: 8, padding: '14px 16px 16px', justifyContent: 'flex-end' }}>
          <button className="pill-btn" style={{ background: 'transparent', color: 'var(--memox-text-secondary)', fontWeight: 700 }}>
            {['parentHoldsCards', 'maxDepth'].includes(state) ? t('Close', 'Đóng') : t('Cancel', 'Huỷ')}
          </button>
          {!['parentHoldsCards', 'maxDepth'].includes(state) &&
            <button className="pill-btn primary">{t('Create', 'Tạo')}</button>}
        </div>
      </Dialog>;
  }

  if (state === 'rename') {
    overlay =
      <Dialog>
        <div style={{ padding: '20px 20px 4px' }}>
          <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.3px', marginBottom: 14 }}>{t('Rename deck', 'Đổi tên bộ thẻ')}</div>
          <FieldLabel len={12} max={200}>{t('NAME', 'TÊN')}</FieldLabel>
          <TextField focused value="Động từ · 동사" />
          <Note style={{ marginTop: 14 }}>{t('Renaming changes nothing else — cards, schedule and history stay as they are.', 'Đổi tên không ảnh hưởng gì khác — thẻ, lịch ôn và lịch sử vẫn nguyên.')}</Note>
        </div>
        <div style={{ display: 'flex', gap: 8, padding: '14px 16px 16px', justifyContent: 'flex-end' }}>
          <button className="pill-btn" style={{ background: 'transparent', color: 'var(--memox-text-secondary)', fontWeight: 700 }}>{t('Cancel', 'Huỷ')}</button>
          <button className="pill-btn primary">{t('Save', 'Lưu')}</button>
        </div>
      </Dialog>;
  }

  if (state === 'move' || state === 'moveRefused') {
    overlay =
      <BottomSheet>
        <SheetHead title={t('Move “Danh từ · 명사”', 'Chuyển “Danh từ · 명사”')}
          sub={t('With its 4 sub-decks and 800 cards', 'Cùng 4 bộ con và 800 thẻ')} />
        {state === 'moveRefused' &&
          <div style={{ padding: '0 16px 10px' }}>
            <Note icon="alert-circle" tone="warning">
              {t('That deck started holding cards a moment ago, so the move was refused. Nothing changed — pick another deck.', 'Bộ đó vừa bắt đầu chứa thẻ nên không thể nhận. Chưa có gì thay đổi — hãy chọn bộ khác.')}
            </Note>
          </div>}
        <div className="hide-scroll" style={{ overflowY: 'auto', padding: '0 8px 8px' }}>
          {TARGETS.map((g) =>
            <button key={g.name} disabled={!g.ok} style={{
              width: '100%', minHeight: 48, display: 'grid', gridTemplateColumns: '28px 1fr auto', gap: 10, alignItems: 'center',
              padding: '8px 8px', paddingLeft: 8 + (g.depth - 1) * 12, background: 'transparent', border: 'none',
              borderRadius: 'var(--memox-radius-md)', textAlign: 'left', fontFamily: 'inherit', color: 'var(--memox-on-surface)',
              opacity: g.ok ? 1 : 0.55, cursor: g.ok ? 'pointer' : 'default'
            }}>
              <span style={{ width: 28, height: 28, borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', background: g.ok ? 'color-mix(in srgb, var(--memox-primary) 10%, transparent)' : 'var(--memox-surface-container)' }}>
                <Ic name={g.ok ? 'folder-tree' : 'layers'} size="xs" color={g.ok ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)'} />
              </span>
              <span style={{ minWidth: 0 }}>
                <span style={{ display: 'block', fontSize: 13.5, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{g.name}</span>
                <span style={{ display: 'block', fontSize: 11.5, color: 'var(--memox-text-secondary)', marginTop: 1 }}>
                  {t(`Level ${g.depth}`, `Mức ${g.depth}`)}{!g.ok ? ` · ${t(g.why.en, g.why.vi)}` : ''}
                </span>
              </span>
              {g.ok ? <Ic name="chevron-right" size="xs" color="var(--memox-text-secondary)" /> : <Ic name="ban" size="xs" color="var(--memox-text-secondary)" />}
            </button>)}
        </div>
        <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
      </BottomSheet>;
  }

  if (state === 'moveNone') {
    overlay =
      <BottomSheet maxHeight="none">
        <SheetHead title={t('Move “한국어 TOPIK I · Từ vựng”', 'Chuyển “한국어 TOPIK I · Từ vựng”')} />
        <div style={{ padding: '0 16px 16px' }}>
          <Note icon="folder-tree">
            {t('This is a top-level deck. Top-level decks stay where they are — only decks inside one can be moved.', 'Đây là bộ ở mức cao nhất. Các bộ mức cao nhất luôn ở vị trí của nó — chỉ bộ bên trong mới di chuyển được.')}
          </Note>
        </div>
        <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
      </BottomSheet>;
  }

  if (state === 'reorder') {
    overlay =
      <BottomSheet maxHeight="none">
        <SheetHead title={t('Reorder decks', 'Sắp xếp lại')} sub={t('Inside 한국어 TOPIK I · Từ vựng', 'Trong 한국어 TOPIK I · Từ vựng')} />
        <div style={{ padding: '0 12px 8px' }}>
          {['Động từ · 동사', 'Danh từ · 명사', 'Tính từ · 형용사', 'Ngữ pháp sơ cấp'].map((n, i) =>
            <div key={n} style={{
              display: 'grid', gridTemplateColumns: '24px 1fr auto auto', gap: 10, alignItems: 'center', minHeight: 48,
              padding: '6px 8px', borderRadius: 'var(--memox-radius-md)',
              background: i === 1 ? 'var(--memox-primary-soft)' : 'transparent'
            }}>
              <Ic name="grip-vertical" size="sm" color="var(--memox-text-secondary)" />
              <span style={{ fontSize: 13.5, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{n}</span>
              <button className="icon-btn" aria-label={t('Move up', 'Lên')} disabled={i === 0}><Ic name="chevron-up" size="sm" /></button>
              <button className="icon-btn" aria-label={t('Move down', 'Xuống')} disabled={i === 3}><Ic name="chevron-down" size="sm" /></button>
            </div>)}
          <Note style={{ margin: '8px 0 4px' }}>{t('Your own order only applies while this level is sorted manually.', 'Thứ tự bạn đặt chỉ áp dụng khi mức này đang sắp xếp thủ công.')}</Note>
        </div>
        <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
      </BottomSheet>;
  }

  if (state === 'delete' || state === 'deleting') {
    overlay =
      <ConfirmDialog title={t('Move “Danh từ · 명사” to Trash?', 'Chuyển “Danh từ · 명사” vào Thùng rác?')}
        confirm={t('Move to Trash', 'Chuyển vào Thùng rác')} busy={state === 'deleting'}>
        {t('4 sub-decks and 800 cards go with it, and any study session open on them ends. Everything stays recoverable in Trash for 30 days.', '4 bộ con và 800 thẻ sẽ đi cùng, phiên học đang mở trên đó sẽ kết thúc. Mọi thứ vẫn phục hồi được trong Thùng rác 30 ngày.')}
      </ConfirmDialog>;
  }

  if (state === 'deletedUndo') overlay = <Snackbar icon="trash-2" action={t('Undo', 'Hoàn tác')}>{t('“Danh từ · 명사” moved to Trash.', 'Đã chuyển “Danh từ · 명사” vào Thùng rác.')}</Snackbar>;
  if (state === 'undoRefused') overlay = <Snackbar icon="alert-circle">{t("Couldn't undo — the deck it came from is in Trash too. Restore it from Trash instead.", 'Không hoàn tác được — bộ cha cũng đang trong Thùng rác. Hãy phục hồi từ Thùng rác.')}</Snackbar>;

  return (
    <div style={{ position: 'relative', height: '100%', width: '100%' }}>
      <Bg state={bgState} />
      {overlay}
    </div>);
}

Object.assign(window, { DeckOps });
})();
