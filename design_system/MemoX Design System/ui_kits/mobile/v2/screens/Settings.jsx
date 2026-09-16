/* MemoX v2 · A22 + A23 — Settings and the daily reminder
   Every option saves on its own (BR-216). Study defaults say they apply to
   future sessions and that decks with their own options keep them (BR-212,
   BR-213). "Reset app options" is deliberately worded so it can never be read
   as resetting learning progress (BR-217). */
(function () {
const { Ic, StatusBar, ScreenScroll, Skeleton, Spinner, Toggle } = window;
const { useT, NavBar, Note, ConfirmDialog, Snackbar } = window;

function Section({ title, children, style }) {
  return (
    <div style={{ marginBottom: 20, ...style }}>
      <div className="ov" style={{ padding: '0 4px 8px' }}>{title}</div>
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>{children}</div>
    </div>);
}
/* V1's settings Row — icon tile, label, subtitle, trailing control or chevron. */
function Row({ icon, iconBg, iconColor, label, sub, right, onClick, last }) {
  return (
    <div role={onClick ? 'button' : undefined} tabIndex={onClick ? 0 : undefined} style={{
      display: 'grid', gridTemplateColumns: icon ? '40px 1fr auto' : '1fr auto', gap: 16, alignItems: 'center',
      minHeight: 56, padding: '16px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)',
      cursor: onClick ? 'pointer' : 'default'
    }}>
      {icon &&
        <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: iconBg || 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Ic name={icon} size="sm" color={iconColor || 'var(--memox-primary)'} />
        </div>}
      <span style={{ minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 16, fontWeight: 600, letterSpacing: '-0.1px' }}>{label}</span>
        {sub ? <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>{sub}</span> : null}
      </span>
      {right || <Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />}
    </div>);
}
function Seg({ options, value, t }) {
  return (
    <div style={{ display: 'flex', gap: 4, padding: 3, borderRadius: 999, background: 'var(--memox-surface-container)' }}>
      {options.map((o) =>
        <button key={o.id} style={{
          height: 30, padding: '0 12px', borderRadius: 999, border: 'none', fontFamily: 'inherit', fontSize: 12.5, fontWeight: 700, cursor: 'pointer',
          background: o.id === value ? 'var(--memox-surface-bright)' : 'transparent',
          color: o.id === value ? 'var(--memox-text-primary)' : 'var(--memox-text-secondary)',
          boxShadow: o.id === value ? 'var(--memox-shadow-soft)' : 'none'
        }}>{t(o.en, o.vi)}</button>)}
    </div>);
}

function Settings({ state = 'loaded' }) {
  const t = useT();
  const invalid = state === 'invalidLimit';

  if (state === 'loading') return (
    <div className="app">
      <StatusBar />
      <div className="appbar appbar-lg"><div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>{t('Settings', 'Cài đặt')}</div></div>
      <ScreenScroll>
        {[0, 1, 2].map((i) => <Skeleton key={i} w="100%" h={i === 0 ? 150 : 110} r={20} op={0.3} style={{ marginBottom: 16 }} />)}
      </ScreenScroll>
      <NavBar active="settings" />
    </div>);

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar appbar-lg">
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>{t('Settings', 'Cài đặt')}</div>
      </div>

      <ScreenScroll>
        <Section title={t('Study defaults', 'Mặc định khi học')}>
          <Row icon="target" label={t('Cards per session', 'Số thẻ mỗi phiên')}
            sub={invalid ? undefined : t('Used by every deck that has no options of its own', 'Dùng cho mọi bộ chưa đặt tuỳ chọn riêng')}
            right={
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <button className="icon-btn" aria-label={t('Fewer', 'Giảm')} style={{ background: 'var(--memox-surface-container)', width: 34, height: 34 }}><Ic name="minus" size="xs" /></button>
                <span style={{ minWidth: 34, textAlign: 'center', fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: invalid ? 'var(--memox-error)' : undefined }}>
                  {invalid ? 0 : 20}
                </span>
                <button className="icon-btn" aria-label={t('More', 'Tăng')} style={{ background: 'var(--memox-surface-container)', width: 34, height: 34 }}><Ic name="plus" size="xs" /></button>
              </div>} />
          {invalid &&
            <div style={{ padding: '0 16px 12px', display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: 'var(--memox-error)' }}>
              <Ic name="alert-circle" size="xs" color="var(--memox-error)" />{t('Between 1 and 200. The saved value is still 20.', 'Từ 1 đến 200. Giá trị đã lưu vẫn là 20.')}
            </div>}
          <Row last icon="shuffle" label={t('New cards arrive', 'Thẻ mới xuất hiện')}
            right={<Seg t={t} value="created" options={[{ id: 'created', en: 'As added', vi: 'Theo thứ tự' }, { id: 'random', en: 'Shuffled', vi: 'Ngẫu nhiên' }]} />} />
        </Section>

        <Note icon="info" style={{ marginTop: -6, marginBottom: 16 }}>
          {t('These apply to sessions started from now on. A deck with its own study options keeps them.', 'Các mục này áp dụng cho phiên bắt đầu từ giờ. Bộ thẻ đã có tuỳ chọn riêng vẫn giữ tuỳ chọn đó.')}
        </Note>

        <Section title={t('Appearance and language', 'Hiển thị và ngôn ngữ')}>
          <Row icon="palette" label={t('Theme', 'Chủ đề')}
            right={<Seg t={t} value="system" options={[{ id: 'system', en: 'System', vi: 'Hệ thống' }, { id: 'light', en: 'Light', vi: 'Sáng' }, { id: 'dark', en: 'Dark', vi: 'Tối' }]} />} />
          <Row last icon="globe" label={t('Language', 'Ngôn ngữ')}
            sub={t('Follows your device, which is set to English', 'Theo thiết bị, hiện là English')}
            right={<Ic name="chevron-right" size="sm" color="var(--memox-text-secondary)" />} onClick />
        </Section>

        <Section title={t('Reminder', 'Nhắc nhở')}>
          <Row last icon="bell" label={t('Daily reminder', 'Nhắc hằng ngày')}
            sub={t('Off — one notification a day, only when cards are due', 'Đang tắt — mỗi ngày một thông báo, chỉ khi có thẻ đến hạn')}
            right={<Ic name="chevron-right" size="sm" color="var(--memox-text-secondary)" />} onClick />
        </Section>

        <Section title={t('App options', 'Tuỳ chọn ứng dụng')}>
          <Row last icon="rotate-ccw" label={t('Reset app options to defaults', 'Đặt lại tuỳ chọn ứng dụng')}
            sub={t('Only the preferences on this screen. Your decks, cards and learning progress are not affected.', 'Chỉ các tuỳ chọn trên màn này. Bộ thẻ, thẻ và tiến trình học không bị ảnh hưởng.')}
            right={<Ic name="chevron-right" size="sm" color="var(--memox-text-secondary)" />} onClick />
        </Section>

        {state === 'saveFailed' &&
          <Note icon="alert-circle" tone="danger">
            {t("Couldn't save the theme. It is still following your device — your other settings were saved.", 'Không lưu được chủ đề. Chủ đề vẫn theo thiết bị — các cài đặt khác đã lưu.')}
          </Note>}

        <div style={{ padding: '4px 4px 0', fontSize: 11, color: 'var(--memox-text-secondary)', lineHeight: 1.5 }}>
          {t('MemoX works entirely on this device. There is no account, and nothing is uploaded.', 'MemoX hoạt động hoàn toàn trên máy này. Không có tài khoản và không có gì được tải lên.')}
        </div>
      </ScreenScroll>

      {state === 'resetConfirm' &&
        <ConfirmDialog title={t('Reset app options?', 'Đặt lại tuỳ chọn ứng dụng?')} confirm={t('Reset options', 'Đặt lại')}>
          {t('Cards per session goes back to 20, new cards to the order you added them, theme and language back to following your device. Your decks, cards, tags and learning progress stay exactly as they are.', 'Số thẻ mỗi phiên trở về 20, thẻ mới theo thứ tự đã thêm, chủ đề và ngôn ngữ trở về theo thiết bị. Bộ thẻ, thẻ, nhãn và tiến trình học của bạn không thay đổi.')}
        </ConfirmDialog>}

      {state === 'savingOne' && <Snackbar icon="loader"><span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}><Spinner color="var(--memox-inverse-primary)" />{t('Saving cards per session…', 'Đang lưu số thẻ mỗi phiên…')}</span></Snackbar>}
      {state === 'saved' && <Snackbar icon="check">{t('Saved. New sessions will use 50 cards.', 'Đã lưu. Các phiên mới sẽ dùng 50 thẻ.')}</Snackbar>}
      {state === 'resetDone' && <Snackbar icon="check">{t('App options are back to their defaults.', 'Tuỳ chọn ứng dụng đã trở về mặc định.')}</Snackbar>}
      <NavBar active="settings" />
    </div>);
}

/* ── A23 · Daily reminder ── */
function Reminder({ state = 'off' }) {
  const t = useT();
  const on = ['on', 'changingTime', 'turningOff'].includes(state);
  const unavailable = state === 'unavailable';

  if (state === 'loading') return (
    <div className="app">
      <StatusBar />
      <div className="appbar"><button className="icon-btn"><Ic name="arrow-left" size="md" /></button><div className="title">{t('Daily reminder', 'Nhắc hằng ngày')}</div></div>
      <ScreenScroll><Skeleton w="100%" h={120} r={20} op={0.3} /></ScreenScroll>
    </div>);

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" aria-label={t('Back', 'Quay lại')}><Ic name="arrow-left" size="md" /></button>
        <div className="title">{t('Daily reminder', 'Nhắc hằng ngày')}</div>
      </div>

      <ScreenScroll>
        {unavailable ?
          <>
            <Note icon="bell-off" tone="warning">
              {t('This device cannot deliver reminders, so there is nothing to switch on here. On a phone, MemoX can remind you once a day.', 'Máy này không gửi được nhắc nhở nên không có gì để bật ở đây. Trên điện thoại, MemoX có thể nhắc bạn mỗi ngày một lần.')}
            </Note>
          </> :
          <>
            <div className="card" style={{ padding: 0, marginBottom: 12, overflow: 'hidden' }}>
              <Row icon="bell" label={t('Remind me daily', 'Nhắc tôi mỗi ngày')}
                sub={state === 'turningOn' ? t('Asking your device for permission…', 'Đang xin quyền từ thiết bị…') : on ? t('On', 'Đang bật') : t('Off', 'Đang tắt')}
                right={state === 'turningOn' ? <Spinner /> : <Toggle on={on} />} last={!on} />
              {on &&
                <Row last icon="clock" label={t('Time', 'Thời điểm')}
                  sub={t('Your local time — it stays 20:00 even if you change time zone', 'Theo giờ địa phương — vẫn là 20:00 dù bạn đổi múi giờ')}
                  right={
                    <span className="pill-btn" style={{ height: 38, padding: '0 14px', background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)', fontWeight: 700, fontVariantNumeric: 'tabular-nums', gap: 6 }}>
                      {state === 'changingTime' ? <Spinner /> : null}20:00
                    </span>}
                  onClick />}
            </div>

            {state === 'permissionDenied' &&
              <div style={{ marginBottom: 12 }}>
                <Note icon="bell-off" tone="warning">
                  {t('Your device refused notifications, so the reminder stays off. Allow notifications for MemoX in your system settings, then turn it on again.', 'Thiết bị đã từ chối thông báo nên nhắc nhở vẫn tắt. Hãy cho phép thông báo cho MemoX trong cài đặt hệ thống rồi bật lại.')}
                </Note>
                <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
                  <button className="pill-btn primary" style={{ flex: 1 }}>{t('Open system settings', 'Mở cài đặt hệ thống')}</button>
                  <button className="pill-btn" style={{ flex: '0 0 96px', background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)' }}>{t('Retry', 'Thử lại')}</button>
                </div>
              </div>}
            {state === 'scheduleFailed' &&
              <Note icon="alert-circle" tone="danger" style={{ marginBottom: 12 }}>
                {t("The reminder couldn't be scheduled, so it stays off. Nothing was saved — try again.", 'Không đặt được nhắc nhở nên vẫn đang tắt. Chưa lưu gì cả — hãy thử lại.')}
              </Note>}
            {state === 'offButMayShow' &&
              <Note icon="info" style={{ marginBottom: 12 }}>
                {t('Reminders are off from now on. A notification sent earlier today may still be on your lock screen until you dismiss it.', 'Từ giờ nhắc nhở đã tắt. Thông báo gửi sớm hơn hôm nay có thể vẫn nằm trên màn hình khoá cho tới khi bạn bỏ nó.')}
              </Note>}

            <div className="card" style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
              <span className="ov" style={{ fontSize: 11 }}>{t('How it behaves', 'Cách hoạt động')}</span>
              {[
                { ic: 'calendar-check', en: 'At most one notification a day, and only if cards are due when it fires.', vi: 'Mỗi ngày nhiều nhất một thông báo, và chỉ khi có thẻ đến hạn lúc đó.' },
                { ic: 'sparkles', en: 'New cards you have never studied never trigger it.', vi: 'Thẻ mới chưa từng học sẽ không kích hoạt nhắc nhở.' },
                { ic: 'lock', en: 'It may name the deck that needs work most and how many cards are due — never the content of a card, including on the lock screen.', vi: 'Thông báo có thể nêu tên bộ cần học nhất và số thẻ đến hạn — không bao giờ nêu nội dung thẻ, kể cả trên màn hình khoá.' },
                { ic: 'hand', en: 'Opening it takes you to Study. It never starts a session by itself.', vi: 'Mở thông báo sẽ đưa bạn tới trang Học. Nó không tự bắt đầu phiên học.' }
              ].map((r) =>
                <div key={r.ic} style={{ display: 'grid', gridTemplateColumns: '18px 1fr', gap: 10, alignItems: 'start' }}>
                  <span style={{ marginTop: 2 }}><Ic name={r.ic} size="xs" color="var(--memox-text-secondary)" /></span>
                  <span style={{ fontSize: 12.5, lineHeight: 1.5, color: 'var(--memox-text-secondary)' }}>{t(r.en, r.vi)}</span>
                </div>)}
            </div>
          </>}
      </ScreenScroll>

      {state === 'turnedOn' && <Snackbar icon="check">{t('Reminder on, daily at 20:00.', 'Đã bật nhắc nhở, 20:00 mỗi ngày.')}</Snackbar>}
    </div>);
}

Object.assign(window, { Settings, Reminder });
})();
