/* MemoX v2 · A9 — Card editor
   Refined from V1 FlashcardEditScreen. KEPT: app bar with the Save pill,
   breadcrumb, the deck-destination chip, the Required overline, V1's
   FieldHeader (label · Required · count/max), the front/back card fields with
   the inline error line, the "Optional details" OptionalField rows, V1's tag
   pills + dashed Add tag, the danger-zone block, and the save bar with its
   caption. REMOVED: the mic/record and speak buttons (cards have no audio) and
   the recall % in the history strip (no accuracy in the product).
   ADDED: the 10-tag limit, the flag toggle, and the missing states. */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, Breadcrumb, Dialog, Toggle } = window;
const { useT, Note } = window;

const FRONT = '눈치';
const BACK = 'sự nhạy cảm trong giao tiếp — khả năng đọc không khí và cảm xúc của người khác';
const EXAMPLE = '그는 눈치가 빠르다. — Anh ấy rất nhanh nhạy.';
const HINT = 'đọc không khí';
const PRON = '[nun.tɕʰi]';

const Spin = (p) => <window.Spinner color="var(--memox-on-primary)" {...p} />;

function FieldHeader({ label, required, count, max, over }) {
  const t = useT();
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8, padding: '0 4px 4px' }}>
      <div style={{ display: 'inline-flex', alignItems: 'baseline', gap: 4 }}>
        <span className="ov">{label}</span>
        {required && <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-primary)', letterSpacing: 0.3 }}>{t('Required', 'Bắt buộc')}</span>}
      </div>
      {count != null &&
        <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.2, fontVariantNumeric: 'tabular-nums', color: over ? 'var(--memox-error)' : 'var(--memox-on-surface-variant)' }}>
          {count} / {max}
        </span>}
    </div>);
}

function OptionalField({ label, icon, value, placeholder }) {
  const t = useT();
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px 4px' }}>
        <Ic name={icon} size="xs" color="var(--memox-on-surface-variant)" />
        <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>{label}</span>
        <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', opacity: 0.55, fontWeight: 500 }}>· {t('optional', 'không bắt buộc')}</span>
      </div>
      <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', padding: '8px 12px', minHeight: 40, fontSize: 14, display: 'flex', alignItems: 'center', lineHeight: 1.45 }}>
        <span style={{ flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: value ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', opacity: value ? 1 : 0.65 }}>
          {value || placeholder}
        </span>
      </div>
    </div>);
}

function CardEditor({ state = 'new' }) {
  const t = useT();
  const create = ['new', 'valid', 'details', 'errFront', 'errBack', 'deckRejects'].includes(state);
  const loading = state === 'loading';
  const errFront = state === 'errFront';
  const errBack = state === 'errBack';
  const saving = state === 'saving';
  const saveFailed = state === 'writeFailed';
  const tagLimit = state === 'tagLimit';
  const details = !['new', 'valid'].includes(state);
  const filled = state !== 'new' && !errFront;
  const front = errFront ? '사회적 거리 두기 · giãn cách xã hội · social distancing 방침 지침' : state === 'new' ? '' : FRONT;
  const back = errBack ? '' : state === 'new' ? '' : BACK;
  const valid = !loading && front && back && !errFront;
  const tags = tagLimit
    ? ['명사', 'thời sự', 'COVID', 'TOPIK II', 'nâng cao', 'y tế', '사회', 'collocation', 'ghi chú dài', 'ôn tập']
    : state === 'new' ? [] : ['명사', 'nâng cao'];

  if (state === 'gone') return (
    <div className="app">
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn"><Ic name="x" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>{t('Edit card', 'Sửa thẻ')}</div>
      </div>
      <ScreenScroll style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div className="card" style={{ padding: '36px 24px', textAlign: 'center', width: '100%' }}>
          <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
            <Ic name="file-question" size="md" color="var(--memox-error)" />
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>{t('This card is gone', 'Thẻ này không còn')}</div>
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16 }}>
            {t('It was moved to Trash somewhere else while you had it open. Nothing you typed was saved.', 'Thẻ đã được chuyển vào Thùng rác ở nơi khác khi bạn đang mở. Nội dung bạn vừa nhập chưa được lưu.')}
          </div>
          <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
            <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>{t('Back to deck', 'Về bộ thẻ')}</button>
            <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>{t('Open Trash', 'Mở Thùng rác')}</button>
          </div>
        </div>
      </ScreenScroll>
    </div>);

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name={create ? 'x' : 'arrow-left'} size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {create ? t('New card', 'Thẻ mới') : t('Edit card', 'Sửa thẻ')}
        </div>
        <button className="pill-btn primary" disabled={!valid || saving} style={{ height: 32, padding: '0 16px', borderRadius: 8, fontSize: 12, gap: 4, opacity: !valid || saving ? 0.45 : 1 }}>
          {saving ? <><Spin size="xs" /> {t('Saving…', 'Đang lưu…')}</> : t('Save', 'Lưu')}
        </button>
      </div>

      <Breadcrumb segments={[{ label: t('Library', 'Thư viện') }, { label: '한국어 TOPIK I · Từ vựng' }, { label: 'Động từ · 동사' }, { label: create ? t('New', 'Mới') : t('Edit', 'Sửa') }]} />

      <ScreenScroll>
        {/* V1's card-history strip — answers and lapses, no accuracy. */}
        {!create && !loading &&
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', marginBottom: 16, fontSize: 12 }}>
            <Ic name="clock" size="xs" color="var(--memox-on-surface-variant)" />
            <span style={{ flex: 1, minWidth: 0, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>
              {t('Beginning · box 2 of 8 ·', 'Bắt đầu · hộp 2/8 ·')} <span style={{ color: 'var(--memox-on-surface)', fontWeight: 600 }}>{t('14 answers', '14 lần trả lời')}</span>
            </span>
            <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'var(--memox-primary)', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4, flexShrink: 0 }}>
              {t('History', 'Lịch sử')}<Ic name="chevron-right" size="xs" color="var(--memox-primary)" />
            </button>
          </div>}

        {/* Deck destination chip */}
        <div role="button" tabIndex={0} style={{ display: 'inline-flex', alignItems: 'center', gap: 8, maxWidth: '100%', padding: '4px 12px 4px 8px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 999, fontSize: 12, fontWeight: 600, marginBottom: 16, cursor: 'pointer' }}>
          <span style={{ width: 22, height: 22, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Ic name="layers" size="xs" color="var(--memox-primary)" />
          </span>
          <span style={{ minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Động từ · 동사</span>
          <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
        </div>

        {state === 'deckRejects' &&
          <Note icon="alert-circle" tone="warning" style={{ marginBottom: 16 }}>
            {t('This deck now holds sub-decks, so it can no longer take cards. Pick another deck to save into.', 'Bộ này giờ chứa bộ con nên không nhận thẻ được nữa. Hãy chọn bộ khác để lưu.')}
          </Note>}

        <div style={{ display: 'flex' }}>
          <div className="ov" style={{ padding: '0 4px 8px', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--memox-primary)' }} />
            {t('Required', 'Bắt buộc')}
          </div>
        </div>

        {/* Front */}
        <FieldHeader label={t('Front · the term', 'Mặt trước · từ cần học')} required count={loading ? null : front.length} max={60} over={errFront} />
        <div className="card" style={{ padding: 16, minHeight: 66, display: 'flex', alignItems: 'center', background: 'var(--memox-surface-container-lowest)', marginBottom: errFront ? 8 : 16, border: errFront ? '1px solid var(--memox-error)' : undefined }}>
          {loading ? <Skeleton w={120} h={22} /> :
            front ?
              <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', lineHeight: 1.25, wordBreak: 'break-word' }}>{front}</div> :
              <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', opacity: 0.65 }}>{t('The word or phrase you want to remember.', 'Từ hoặc cụm từ bạn muốn nhớ.')}</div>}
        </div>
        {errFront &&
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px', color: 'var(--memox-error)', fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <span>{t('4 characters over the 60 limit.', 'Vượt giới hạn 60 ký tự 4 ký tự.')}</span>
          </div>}

        {/* Back */}
        <FieldHeader label={t('Back · the meaning', 'Mặt sau · nghĩa')} required count={loading ? null : back.length} max={240} />
        <div className="card" style={{ padding: '12px 16px', minHeight: 76, background: 'var(--memox-surface-container-lowest)', display: 'flex', alignItems: loading || !back ? 'center' : 'flex-start', marginBottom: errBack ? 8 : 16, border: errBack ? '1px solid var(--memox-error)' : undefined }}>
          {loading ?
            <div style={{ width: '100%' }}>
              <Skeleton w="80%" h={13} /><div style={{ height: 6 }} /><Skeleton w="55%" h={13} op={0.35} />
            </div> :
            back ?
              <div style={{ fontSize: 16, fontWeight: 500, lineHeight: 1.45, wordBreak: 'break-word' }}>{back}</div> :
              <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', opacity: 0.65, lineHeight: 1.5 }}>
                {t('Vietnamese, English, or both — comma-separated reads cleanest.', 'Tiếng Việt, tiếng Anh, hoặc cả hai — cách nhau bằng dấu phẩy là dễ đọc nhất.')}
              </div>}
        </div>
        {errBack &&
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px', color: 'var(--memox-error)', fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <span>{t('Add a meaning so this card can be answered.', 'Hãy thêm nghĩa để thẻ này có thể trả lời được.')}</span>
          </div>}

        {/* Optional details */}
        <div className="ov" style={{ padding: '2px 4px 8px' }}>{t('Optional details', 'Chi tiết không bắt buộc')}</div>
        {loading ?
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 20 }}>
            {[0, 1, 2].map((i) =>
              <div key={i} style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', padding: '12px 16px' }}>
                <Skeleton w={90} h={9} op={0.4} /><div style={{ height: 8 }} /><Skeleton w={i === 1 ? '70%' : '60%'} h={12} />
              </div>)}
          </div> :
          details ?
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 20 }}>
              <OptionalField icon="message-square" label={t('Example sentence', 'Câu ví dụ')} value={filled ? EXAMPLE : ''} placeholder={t('A sentence using the term', 'Một câu dùng từ này')} />
              <OptionalField icon="lightbulb" label={t('Hint', 'Gợi ý')} value={filled ? HINT : ''} placeholder={t('Shown on request while typing the term', 'Hiện khi bạn yêu cầu lúc điền từ')} />
              <OptionalField icon="type" label={t('Pronunciation', 'Phát âm')} value={filled ? PRON : ''} placeholder="[nun.tɕʰi]" />
            </div> :
            <button className="pill-btn" style={{ width: '100%', marginBottom: 20, justifyContent: 'space-between', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', color: 'var(--memox-on-surface)', fontWeight: 600 }}>
              {t('Add example, hint, pronunciation', 'Thêm ví dụ, gợi ý, phát âm')}
              <Ic name="chevron-down" size="sm" color="var(--memox-on-surface-variant)" />
            </button>}

        {/* Tags */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px 8px' }}>
          <Ic name="tag" size="xs" color="var(--memox-on-surface-variant)" />
          <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.4, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>{t('Tags', 'Nhãn')}</span>
          <span style={{ flex: 1, fontSize: 12, color: 'var(--memox-on-surface-variant)', opacity: 0.55, fontWeight: 500 }}>· {t('optional', 'không bắt buộc')}</span>
          <span style={{ fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: tagLimit ? 'var(--memox-error)' : 'var(--memox-on-surface-variant)' }}>{tags.length} / 10</span>
        </div>
        {loading ?
          <div style={{ display: 'flex', gap: 4, marginBottom: 24 }}>
            <Skeleton w={70} h={26} /><Skeleton w={56} h={26} /><Skeleton w={64} h={26} />
          </div> :
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginBottom: tagLimit ? 8 : 24 }}>
            {tags.map((g) =>
              <span key={g} style={{ height: 28, padding: '0 8px 0 12px', background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', borderRadius: 999, fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4, maxWidth: '100%' }}>
                <span style={{ minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{g}</span>
                <Ic name="x" size="xs" color="var(--memox-primary)" />
              </span>)}
            {!tagLimit &&
              <button style={{ height: 28, padding: '0 12px', background: 'transparent', color: 'var(--memox-on-surface-variant)', border: '1px dashed var(--memox-outline-variant)', borderRadius: 999, fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4, fontFamily: 'inherit', cursor: 'pointer' }}>
                <Ic name="plus" size="xs" color="var(--memox-on-surface-variant)" />{t('Add tag', 'Thêm nhãn')}
              </button>}
          </div>}
        {tagLimit &&
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px', color: 'var(--memox-warning-ink)', fontSize: 12, fontWeight: 600, marginBottom: 24 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-warning)" />
            <span>{t('A card can carry 10 tags. Remove one to add another.', 'Một thẻ chỉ mang được 10 nhãn. Hãy bỏ một nhãn để thêm nhãn khác.')}</span>
          </div>}

        {/* Flag */}
        <div className="card" style={{ padding: '14px 16px', marginBottom: 24, display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center' }}>
          <span style={{ minWidth: 0 }}>
            <span style={{ display: 'block', fontSize: 16, fontWeight: 600, letterSpacing: '-0.1px' }}>{t('Flag this card', 'Gắn cờ thẻ này')}</span>
            <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>
              {t('Flagged cards have their own filter in the deck.', 'Thẻ có cờ có bộ lọc riêng trong bộ thẻ.')}
            </span>
          </span>
          <Toggle on={filled} />
        </div>

        {!create &&
          <>
            <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: '0 4px 24px' }} />
            <div className="ov" style={{ padding: '0 4px 8px' }}>{t('Remove', 'Xoá bỏ')}</div>
            <div className="card" style={{ padding: 16, marginBottom: 24 }}>
              <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{t('Move this card to Trash', 'Chuyển thẻ này vào Thùng rác')}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 12 }}>
                {t('The card and its review history stay recoverable for 30 days. Other cards in the deck are unaffected.', 'Thẻ và lịch sử học của nó vẫn phục hồi được trong 30 ngày. Các thẻ khác trong bộ không bị ảnh hưởng.')}
              </div>
              <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
                <Ic name="trash-2" size="xs" color="var(--memox-primary)" />{t('Move to Trash', 'Chuyển vào Thùng rác')}
              </button>
            </div>
            <Note icon="lock" style={{ marginBottom: 8 }}>
              {t('Changing the text leaves the schedule and the review history exactly as they are.', 'Sửa nội dung không làm thay đổi lịch ôn và lịch sử học.')}
            </Note>
          </>}
      </ScreenScroll>

      {/* Save bar */}
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {saveFailed &&
          <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-danger) 8%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-danger) 22%, transparent)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'flex-start' }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <div style={{ flex: 1, fontSize: 12, lineHeight: 1.45 }}>
              <strong style={{ fontWeight: 700 }}>{t("Couldn't save this card.", 'Không lưu được thẻ này.')}</strong>{' '}
              <span style={{ color: 'var(--memox-on-surface-variant)' }}>{t('Nothing was written and your text is still here.', 'Chưa ghi gì cả và nội dung của bạn vẫn còn.')}</span>
            </div>
          </div>}
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 12, fontSize: 14, flexShrink: 0 }}>{t('Cancel', 'Huỷ')}</button>
          <button className="pill-btn primary" disabled={!valid || saving} style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: !valid || saving ? 0.45 : 1 }}>
            {saving ? <><Spin size="xs" /> {t('Saving…', 'Đang lưu…')}</> :
              saveFailed ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" /> {t('Retry save', 'Lưu lại')}</> :
                <><Ic name="check" size="xs" color="var(--memox-on-primary)" /> {create ? t('Save card', 'Lưu thẻ') : t('Save changes', 'Lưu thay đổi')}</>}
          </button>
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.8 }}>
          {loading ? t('Loading card…', 'Đang tải thẻ…')
            : errBack || errFront ? t('Fix the field above to enable save.', 'Hãy sửa ô ở trên để lưu được.')
              : saving ? t('Saving to this device…', 'Đang lưu vào máy này…')
                : create ? t('New cards start unscheduled — learn them when you like.', 'Thẻ mới chưa có lịch — bạn học lúc nào cũng được.')
                  : t('Changes save to this device only.', 'Thay đổi chỉ lưu trên máy này.')}
        </div>
      </div>

      {state === 'saved' && <window.Snackbar icon="check">{t('Card saved. Schedule and history untouched.', 'Đã lưu thẻ. Lịch ôn và lịch sử không đổi.')}</window.Snackbar>}

      {state === 'discard' &&
        <Dialog>
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 8 }}>{t('Discard this card?', 'Bỏ thẻ này?')}</div>
            <div style={{ padding: '12px 16px', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', border: 'var(--memox-border-ghost)' }}>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>{FRONT}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.45 }}>{BACK}</div>
            </div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginTop: 12 }}>
              {t('You have typed a front and a back. Leaving now keeps nothing.', 'Bạn đã nhập mặt trước và mặt sau. Thoát bây giờ sẽ không giữ lại gì.')}
            </div>
          </div>
          <div style={{ padding: 16, display: 'flex', gap: 8 }}>
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>{t('Keep editing', 'Tiếp tục sửa')}</button>
            <button className="pill-btn" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface)', fontWeight: 600 }}>
              {t('Discard', 'Bỏ')}
            </button>
          </div>
        </Dialog>}
    </div>);
}

Object.assign(window, { CardEditor });
})();
