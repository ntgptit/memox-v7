/* MemoX v2 — shared kit for the product-truth screens.
   Loads AFTER ../screens/_shared.jsx (which owns Ic, MobileScaffold, Dialog,
   BottomSheet, Skeleton, Spinner, EmptyState, ErrorState, Toggle, TextField,
   StatusBadge, Badge, ListRow, IconTile, Fab, SearchField, Breadcrumb).
   What lives here is what the redesign needs and the old kit does not have:
   the four-area nav, the EN/VI copy switch, and the count vocabulary that
   keeps New and Due apart (BR-150) and Scheduled calm (BR-162). */
(function () {
const { Badge, StatusBadge, Dialog, BottomSheet } = window;

/* ── Icons ─────────────────────────────────────────────────────────────
   The kit's own <Ic> calls lucide.createIcons() per icon instance, and each
   call scans the whole document — on a wall of 40 phone frames that is
   quadratic and freezes the page. This version registers the placeholder and
   flushes every pending icon in ONE createIcons() pass per microtask, then
   fixes each svg's size and colour. Same props, same output. */
const ICON = window.ICON;
/* lucide.createIcons() scans the WHOLE document on every call, which is
   quadratic on a page holding forty phone frames. Building each glyph straight
   from its icon node touches nothing outside this element. */
const pascal = (n) => n.split(/[-_]/).map((p) => p.charAt(0).toUpperCase() + p.slice(1)).join('');
const svgCache = new Map();
function iconSvg(name) {
  if (svgCache.has(name)) return svgCache.get(name);
  const lucide = window.lucide;
  const node = lucide && lucide.icons && (lucide.icons[pascal(name)] || lucide.icons[name]);
  let el = null;
  if (node && lucide.createElement) { try { el = lucide.createElement(node); } catch (e) { el = null; } }
  svgCache.set(name, el);
  return el;
}
function Ic({ name, size = 'sm', color, label }) {
  const px = typeof size === 'number' ? size : (ICON[size] || ICON.sm);
  const ref = React.useRef();
  React.useEffect(() => {
    const host = ref.current;
    if (!host) return;
    const proto = iconSvg(name);
    host.textContent = '';
    if (!proto) return;
    const svg = proto.cloneNode(true);
    svg.setAttribute('width', px);
    svg.setAttribute('height', px);
    svg.style.display = 'block';
    if (color) svg.style.stroke = color;
    host.appendChild(svg);
  }, [name, px, color]);
  const a11y = label ? { role: 'img', 'aria-label': label } : { 'aria-hidden': 'true' };
  return <span ref={ref} {...a11y} style={{ display: 'inline-flex', lineHeight: 0 }} />;
}

/* ── Copy language ─────────────────────────────────────────────────────
   Card CONTENT is never translated — only chrome. t(en, vi) reads the
   current language from context, so copy stays at its use site. */
const LangCtx = React.createContext('en');
function LangProvider({ lang, children }) { return <LangCtx.Provider value={lang}>{children}</LangCtx.Provider>; }
function useT() {
  const lang = React.useContext(LangCtx);
  const t = (en, vi) => (lang === 'vi' && vi !== undefined ? vi : en);
  t.lang = lang;
  t.n = (n) => Number(n).toLocaleString(lang === 'vi' ? 'vi-VN' : 'en-US');
  return t;
}

/* ── Four top-level areas, Library first (AD-19) ── */
const NAV = [
  { id: 'library', icon: 'library', en: 'Library', vi: 'Thư viện' },
  { id: 'study', icon: 'graduation-cap', en: 'Study', vi: 'Học' },
  { id: 'progress', icon: 'trending-up', en: 'Progress', vi: 'Tiến độ' },
  { id: 'settings', icon: 'settings', en: 'Settings', vi: 'Cài đặt' }
];
function NavBar({ active = 'library', onChange = () => {} }) {
  const t = useT();
  return (
    <div className="bottom-nav-wrap">
      <div className="bottom-nav" role="navigation" aria-label={t('Primary', 'Chính')}>
        {NAV.map((it) => {
          const on = active === it.id;
          const label = t(it.en, it.vi);
          return (
            <button type="button" key={it.id} aria-current={on ? 'page' : undefined} aria-label={label}
              className={'bn-item' + (on ? ' active' : '')} onClick={() => onChange(it.id)}>
              <span className="bn-pill"><Ic name={it.icon} size="md" /></span>
              <span>{label}</span>
            </button>);
        })}
      </div>
    </div>);
}

/* ── Count vocabulary ──────────────────────────────────────────────────
   One chip per kind, each carrying its own word so meaning never rests on
   colour (BR-204/243). Overdue is attention (amber), due today is the
   primary call, new is neutral-cool, scheduled is plain text — resting
   cards are not a warning (BR-162). */
const COUNT_TONE = {
  overdue: { c: 'var(--memox-warning)', ink: 'var(--memox-warning-ink)' },
  dueToday: { c: 'var(--memox-primary)' },
  due: { c: 'var(--memox-primary)' },
  /* New is a neutral count, not a warning — full-strength secondary ink on the
     container tint, so it clears AA where a tinted grey-on-grey did not. */
  new: { c: 'var(--memox-text-secondary)', bg: 'var(--memox-surface-container-high)' }
};
function CountChip({ kind = 'due', n, label, icon, style }) {
  const tone = COUNT_TONE[kind] || COUNT_TONE.due;
  const c = tone.c;
  const t = useT();
  return (
    <span style={{
      height: 24, padding: icon ? '0 9px 0 7px' : '0 9px', borderRadius: 999, flexShrink: 0,
      display: 'inline-flex', alignItems: 'center', gap: 5, fontSize: 12, fontWeight: 700, lineHeight: 1,
      whiteSpace: 'nowrap', fontVariantNumeric: 'tabular-nums', color: tone.ink || c,
      background: tone.bg || `color-mix(in srgb, ${c} 13%, transparent)`, ...style
    }}>
      {icon ? <Ic name={icon} size="xs" color={c} /> : null}
      {t.n(n)} {label}
    </span>);
}

/* DeckCounts — the two numbers a deck row must show, never merged (BR-150).
   Overdue splits out of Due only when there is an overdue card. */
function DeckCounts({ d, showNew = true, style }) {
  const t = useT();
  const chips = [];
  if (d.overdue > 0) chips.push(<CountChip key="o" kind="overdue" n={d.overdue} label={t('overdue', 'quá hạn')} icon="alert-circle" />);
  if (d.dueToday > 0) chips.push(<CountChip key="t" kind="dueToday" n={d.dueToday} label={t('due today', 'hôm nay')} />);
  if (showNew && d.new > 0) chips.push(<CountChip key="n" kind="new" n={d.new} label={t('new', 'thẻ mới')} />);
  if (!chips.length) return null;
  return <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, ...style }}>{chips}</div>;
}

/* LevelTotals — the sums for the level being shown (A1 required info).
   Scheduled and total stay as quiet text on the same line. */
function LevelTotals({ totals, label, style }) {
  const t = useT();
  const nothing = !totals.overdue && !totals.dueToday && !totals.new;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, padding: '10px 14px', borderRadius: 'var(--memox-radius-lg)', background: 'var(--memox-surface-container-low)', ...style }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
        <span className="ov" style={{ fontSize: 11 }}>{label}</span>
        <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums' }}>
          {t.n(totals.total)} {t('cards', 'thẻ')}
        </span>
      </div>
      {nothing ?
        <div style={{ fontSize: 12, color: 'var(--memox-text-secondary)' }}>
          {t('Nothing due at this level', 'Không có thẻ đến hạn ở mức này')}
        </div> :
        <DeckCounts d={totals} />}
      {totals.scheduled > 0 &&
        <span style={{ fontSize: 12, color: 'var(--memox-text-secondary)', fontVariantNumeric: 'tabular-nums' }}>
          {t.n(totals.scheduled)} {t('scheduled for later', 'đã lên lịch cho sau này')}
        </span>}
    </div>);
}

/* ── Deck identity ────────────────────────────────────────────────────
   contentType is the system's, never the user's (BR-163) — so it reads as
   a quiet fact, expressed by glyph + what the deck contains. */
const CONTENT = {
  deck: { icon: 'folder-tree', en: 'sub-decks', vi: 'bộ con' },
  card: { icon: 'layers', en: 'cards', vi: 'thẻ' },
  unset: { icon: 'square-dashed', en: 'empty', vi: 'trống' }
};
function deckContentLabel(d, t) {
  if (d.contentType === 'unset') return t('Empty · add cards or sub-decks', 'Trống · thêm thẻ hoặc bộ con');
  if (d.contentType === 'deck') return `${t.n(d.subDecks)} ${t('sub-decks', 'bộ con')} · ${t.n(d.total)} ${t('cards', 'thẻ')}`;
  return `${t.n(d.total)} ${t('cards', 'thẻ')}`;
}

/* Review schedule = the algorithm (eight_box | sm2). Study mode = the
   question format. Keeping the two words apart is the copy decision. */
const SCHED = { eight_box: { en: 'Eight boxes', vi: 'Tám hộp' }, sm2: { en: 'SM-2', vi: 'SM-2' } };
function schedLabel(s, t) { const v = SCHED[s]; return v ? t(v.en, v.vi) : ''; }
const MODE = {
  browse: { en: 'Browse', vi: 'Xem trước', icon: 'book-open' },
  self_assess: { en: 'Self-assess', vi: 'Tự đánh giá', icon: 'scale' },
  match: { en: 'Match', vi: 'Ghép cặp', icon: 'shuffle' },
  guess: { en: 'Guess', vi: 'Chọn nghĩa', icon: 'list-checks' },
  recall: { en: 'Recall', vi: 'Nhớ lại', icon: 'timer' },
  fill: { en: 'Fill', vi: 'Điền từ', icon: 'keyboard' }
};
function modeLabel(m, t) { const v = MODE[m]; return v ? t(v.en, v.vi) : m; }

/* Card display state — derived, never stored (BR-88…91). */
const CARD_STATE = {
  new: { status: 'new', en: 'New', vi: 'Mới' },
  beginning: { status: 'learning', en: 'Beginning', vi: 'Bắt đầu' },
  reviewing: { status: 'reviewing', en: 'Reviewing', vi: 'Đang ôn' },
  mastered: { status: 'mastered', en: 'Mastered', vi: 'Thành thạo' }
};
function CardStateBadge({ state = 'new', dot = false, style }) {
  const t = useT();
  const s = CARD_STATE[state] || CARD_STATE.new;
  return <StatusBadge status={s.status} dot={dot} label={t(s.en, s.vi)} style={style} />;
}

/* ── Path ─────────────────────────────────────────────────────────────
   Up to 10 levels, so the middle collapses and only the two nearest
   ancestors stay legible. */
function PathBar({ ancestors = [], current, style }) {
  const t = useT();
  const long = ancestors.length > 3;
  const shown = long ? [ancestors[0], { id: '…', name: '…', ellipsis: true }, ancestors[ancestors.length - 1]] : ancestors;
  return (
    <div className="scroll-x" style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 16px 8px', fontSize: 12, ...style }}>
      <span style={{ color: 'var(--memox-text-secondary)', fontWeight: 600, whiteSpace: 'nowrap' }}>{t('Library', 'Thư viện')}</span>
      {shown.map((a, i) =>
        <React.Fragment key={a.id + String(i)}>
          <Ic name="chevron-right" size="xs" color="var(--memox-outline)" />
          <span title={a.name} style={{
            color: 'var(--memox-text-secondary)', fontWeight: 600, whiteSpace: 'nowrap',
            maxWidth: a.ellipsis ? 'none' : 120, overflow: 'hidden', textOverflow: 'ellipsis'
          }}>{a.ellipsis ? '…' : a.name}</span>
        </React.Fragment>)}
      {current ?
        <>
          <Ic name="chevron-right" size="xs" color="var(--memox-outline)" />
          <span style={{ color: 'var(--memox-on-surface)', fontWeight: 700, whiteSpace: 'nowrap', maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis' }}>{current}</span>
        </> : null}
      {long &&
        <span style={{ marginLeft: 4, fontSize: 11, fontWeight: 700, color: 'var(--memox-text-secondary)', whiteSpace: 'nowrap' }}>
          {t(`level ${ancestors.length + 1}/10`, `mức ${ancestors.length + 1}/10`)}
        </span>}
    </div>);
}

/* ── Small shared bits ── */
function Chip({ label, active, count, onClick, disabled, style }) {
  return (
    <button type="button" className="pill-btn" disabled={disabled} onClick={onClick} style={{
      height: 32, padding: '0 12px', borderRadius: 999, fontSize: 13, fontWeight: 600, gap: 6, flexShrink: 0,
      background: active ? 'var(--memox-primary)' : 'var(--memox-surface-container)',
      color: active ? 'var(--memox-on-primary)' : 'var(--memox-text-primary)',
      opacity: disabled ? 'var(--memox-op-disabled)' : 1, ...style
    }}>
      {label}
      {count !== undefined &&
        <span style={{ fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', opacity: active ? 0.9 : 0.6 }}>{count}</span>}
    </button>);
}
function ChipRow({ children, style }) {
  return <div className="scroll-x" style={{ display: 'flex', gap: 8, padding: '0 16px 10px', ...style }}>{children}</div>;
}
/* MasteryLine — optional info, so it carries no number in a list row. */
function MasteryLine({ fraction = 0, style }) {
  return (
    <div style={{ height: 4, borderRadius: 999, background: 'var(--memox-progress-track)', overflow: 'hidden', ...style }}>
      <div style={{ height: '100%', width: `${Math.max(fraction * 100, fraction > 0 ? 2 : 0)}%`, background: 'var(--memox-status-mastered)', borderRadius: 999 }} />
    </div>);
}
/* Note — inline explanation of a rule, never an alarm. */
function Note({ icon = 'info', tone = 'neutral', children, style }) {
  const c = tone === 'warning' ? 'var(--memox-warning)' : tone === 'danger' ? 'var(--memox-error)' : 'var(--memox-text-secondary)';
  const bg = tone === 'neutral' ? 'var(--memox-surface-container-low)' : `color-mix(in srgb, ${c} 10%, transparent)`;
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'flex-start', padding: '10px 12px', borderRadius: 'var(--memox-radius-md)', background: bg, fontSize: 12, lineHeight: 1.5, color: 'var(--memox-text-secondary)', ...style }}>
      <span style={{ flexShrink: 0, marginTop: 1 }}><Ic name={icon} size="xs" color={c} /></span>
      <span style={{ minWidth: 0 }}>{children}</span>
    </div>);
}
/* SheetHead / ActionRow — the action-sheet vocabulary every list reuses. */
function SheetHead({ title, sub, style }) {
  return (
    <div style={{ padding: '4px 16px 10px', ...style }}>
      <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: '-0.2px', wordBreak: 'break-word' }}>{title}</div>
      {sub ? <div style={{ fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 2 }}>{sub}</div> : null}
    </div>);
}
function ActionRow({ icon, label, sub, danger, disabled, onClick, trailing }) {
  const col = danger ? 'var(--memox-error)' : 'var(--memox-primary)';
  return (
    <button type="button" disabled={disabled} onClick={onClick} style={{
      width: '100%', minHeight: 48, display: 'grid', gridTemplateColumns: '30px 1fr auto', gap: 12, alignItems: 'center',
      padding: '10px 8px', background: 'transparent', border: 'none', borderRadius: 'var(--memox-radius-md)',
      color: 'var(--memox-on-surface)', fontFamily: 'inherit', textAlign: 'left',
      opacity: disabled ? 'var(--memox-op-disabled)' : 1, cursor: disabled ? 'default' : 'pointer'
    }}>
      <span style={{ width: 30, height: 30, borderRadius: 8, background: `color-mix(in srgb, ${col} 10%, transparent)`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Ic name={icon} size="xs" color={col} />
      </span>
      <span style={{ minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', color: danger ? 'var(--memox-error)' : undefined }}>{label}</span>
        {sub ? <span style={{ display: 'block', fontSize: 12, color: 'var(--memox-text-secondary)', marginTop: 2, lineHeight: 1.45 }}>{sub}</span> : null}
      </span>
      {trailing || <span />}
    </button>);
}
/* ConfirmDialog — destructive emphasis only for permanent deletion (BR-266):
   `tone="danger"` is reserved for it, everything else confirms in primary. */
function ConfirmDialog({ title, children, cancel, confirm, tone = 'primary', onDismiss, busy }) {
  const t = useT();
  return (
    <Dialog onDismiss={onDismiss}>
      <div style={{ padding: '20px 20px 8px' }}>
        <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: '-0.3px', marginBottom: 8, wordBreak: 'break-word' }}>{title}</div>
        <div style={{ fontSize: 13.5, lineHeight: 1.55, color: 'var(--memox-text-secondary)' }}>{children}</div>
      </div>
      <div style={{ display: 'flex', gap: 8, padding: '12px 16px 16px', justifyContent: 'flex-end' }}>
        <button className="pill-btn" style={{ background: 'transparent', color: 'var(--memox-text-secondary)', fontWeight: 700 }}>{cancel || t('Cancel', 'Huỷ')}</button>
        <button className="pill-btn" style={{
          background: tone === 'danger' ? 'var(--memox-error-fill)' : 'var(--memox-primary)',
          color: tone === 'danger' ? 'var(--memox-on-error-fill)' : 'var(--memox-on-primary)', fontWeight: 700, gap: 6
        }}>
          {busy ? <window.Spinner color={tone === 'danger' ? 'var(--memox-on-error-fill)' : 'var(--memox-on-primary)'} /> : null}
          {confirm}
        </button>
      </div>
    </Dialog>);
}
/* Snackbar — fixed dark slate in both themes (the kit's invariant inverse). */
function Snackbar({ children, action, icon, style }) {
  return (
    <div role="status" style={{
      position: 'absolute', left: 12, right: 12, bottom: 'calc(var(--memox-size-bottom-nav) + 8px)', zIndex: 60,
      display: 'flex', alignItems: 'center', gap: 10, padding: '12px 12px 12px 14px', borderRadius: 'var(--memox-radius-md)',
      background: 'var(--memox-inverse-surface)', color: 'var(--memox-on-inverse-surface)', boxShadow: 'var(--memox-shadow-card)', ...style
    }}>
      {icon ? <Ic name={icon} size="xs" color="var(--memox-on-inverse-surface)" /> : null}
      <span style={{ flex: 1, fontSize: 13, lineHeight: 1.45, minWidth: 0 }}>{children}</span>
      {action ?
        <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--memox-inverse-primary)', whiteSpace: 'nowrap', textTransform: 'uppercase', letterSpacing: 0.4 }}>{action}</span> : null}
    </div>);
}
/* FieldLabel + counter — every text field states its limit up front. */
function FieldLabel({ children, len, max, error, style }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8, marginBottom: 6, ...style }}>
      <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.2, color: 'var(--memox-text-secondary)' }}>{children}</span>
      {max !== undefined &&
        <span style={{ fontSize: 11, fontWeight: 600, fontVariantNumeric: 'tabular-nums', color: error ? 'var(--memox-error)' : 'var(--memox-text-secondary)' }}>{len}/{max}</span>}
    </div>);
}
function TagPill({ name, onRemove, style }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4, maxWidth: '100%', height: 26, padding: onRemove ? '0 4px 0 10px' : '0 10px',
      borderRadius: 999, background: 'var(--memox-surface-container)', color: 'var(--memox-text-primary)',
      fontSize: 12, fontWeight: 600, ...style
    }}>
      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{name}</span>
      {onRemove ? <span style={{ display: 'inline-flex' }}><Ic name="x" size="xs" color="var(--memox-text-secondary)" /></span> : null}
    </span>);
}

Object.assign(window, {
  Ic,
  LangProvider, useT, NavBar, NAV, CountChip, DeckCounts, LevelTotals, deckContentLabel,
  SCHED, schedLabel, MODE, modeLabel, CARD_STATE, CardStateBadge, PathBar,
  Chip, ChipRow, MasteryLine, Note, SheetHead, ActionRow, ConfirmDialog, Snackbar, FieldLabel, TagPill
});
})();
