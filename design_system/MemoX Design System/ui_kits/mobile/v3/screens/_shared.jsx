/* MemoX Mobile — shared primitives & layout chrome
   Loaded FIRST (before every screen file). Wrapped in an IIFE; publishes the
   shared chrome to window so each screen file can read it via
   const { StatusBar, Ic, BottomNav, Breadcrumb, StudyTopBar, masteryColor } = window;
   Edit shared chrome (status bar, bottom nav, icon wrapper, study top bar, mastery ramp) here. */
(function () {
const { useState, useEffect } = React;

function StatusBar() {
  return (
    <div className="statusbar">
      <span>9:41</span>
      <span style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
        <svg width="16" height="12" viewBox="0 0 16 12" fill="currentColor"><path d="M1 11h2V7H1v4zm4 0h2V4H5v7zm4 0h2V1H9v10zm4 0h2V8h-2v3z" /></svg>
        <svg width="14" height="12" viewBox="0 0 14 12" fill="currentColor"><path d="M7 10.3a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4zm0-3a3 3 0 0 1 2.12.88l1.06-1.06a4.5 4.5 0 0 0-6.36 0l1.06 1.06A3 3 0 0 1 7 7.3zm0-3a6 6 0 0 1 4.24 1.76l1.07-1.07a7.5 7.5 0 0 0-10.62 0l1.07 1.07A6 6 0 0 1 7 4.3z" /></svg>
        <svg width="22" height="12" viewBox="0 0 22 12" fill="none"><rect x="1" y="1" width="18" height="10" rx="2" stroke="currentColor" strokeOpacity=".4" /><rect x="2.5" y="2.5" width="13" height="7" rx="1" fill="currentColor" /><rect x="20" y="4" width="1.5" height="4" rx=".5" fill="currentColor" /></svg>
      </span>
    </div>);

}

// Single-color mastery fill — replaces tri-stop gradient.
// Returns the appropriate status color token based on percentage thresholds.
function masteryColor(pct) {
  if (pct < 0.34) return 'var(--memox-status-learning)'; // amber — early
  if (pct < 0.67) return 'var(--memox-status-reviewing)'; // primary — mid
  return 'var(--memox-status-mastered)'; // green — high
}

/* Semantic icon scale — the only sizes the kit may paint. Mirrors
   --memox-size-icon-* in colors_and_type.css; kept here as JS because `size`
   is an SVG width/height attribute, not a CSS property.
     xs 16  inline / compact utility — the floor for any UI icon
     sm 20  small control, metadata, dense rows
     md 24  standard action + navigation
     lg 32  visual emphasis
     xl 40  illustrative (empty states, hero marks)
   A raw number still works for the documented exceptions; everything else
   passes a step name. */
const ICON = { xs: 16, sm: 20, md: 24, lg: 32, xl: 40 };

function Ic({ name, size = 'sm', color, label }) {
  const px = typeof size === 'number' ? size : (ICON[size] || ICON.sm);
  const ref = React.useRef();
  React.useEffect(() => {
    if (ref.current && window.lucide) {
      ref.current.innerHTML = '';
      const i = document.createElement('i');
      i.setAttribute('data-lucide', name);
      ref.current.appendChild(i);
      window.lucide.createIcons({ icons: window.lucide.icons });
      const svg = ref.current.querySelector('svg');
      if (svg) {
        svg.setAttribute('width', px);
        svg.setAttribute('height', px);
        if (color) svg.style.stroke = color;
      }
    }
  }, [name, px, color]);
  // Icons are decorative by default (the surrounding button/text carries meaning).
  // Pass `label` only when the icon is the sole carrier of meaning.
  const a11y = label ? { role: 'img', 'aria-label': label } : { 'aria-hidden': 'true' };
  return <span ref={ref} {...a11y} style={{ display: 'inline-flex', lineHeight: 0 }} />;
}

/* Breadcrumb — folder/deck/card hierarchy path. Last segment is the current location. */
function Breadcrumb({ segments }) {
  return (
    <div className="scroll-x" style={{
      display: 'flex', alignItems: 'center', gap: 4,
      padding: '2px 16px 8px',
      fontSize: 12
    }}>
      {segments.map((s, i) => {
        const last = i === segments.length - 1;
        return (
          <React.Fragment key={i}>
            <span style={{
              color: last ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)',
              fontWeight: last ? 700 : 500,
              whiteSpace: 'nowrap',
              cursor: last ? 'default' : 'pointer',
              letterSpacing: 0.1
            }}>{s.label}</span>
            {!last && <Ic name="chevron-right" size="xs" color="var(--memox-outline)" />}
          </React.Fragment>);

      })}
    </div>);

}

function BottomNav({ active, onChange }) {
  /* v3: the product has exactly four top-level areas, in this order (AD-19).
     The app opens into Library. */
  const items = [
  { id: 'library', icon: 'layers', label: 'Library' },
  { id: 'study', icon: 'play', label: 'Study' },
  { id: 'progress', icon: 'bar-chart-3', label: 'Progress' },
  { id: 'settings', icon: 'settings', label: 'Settings' }];

  return (
    <div className="bottom-nav-wrap">
      <div className="bottom-nav" role="navigation" aria-label="Primary">
        {items.map((it) =>
        <button type="button" key={it.id}
          aria-current={active === it.id ? 'page' : undefined}
          aria-label={it.label}
          className={"bn-item " + (active === it.id ? 'active' : '')} onClick={() => onChange(it.id)}>
            <span className="bn-pill"><Ic name={it.icon} size="md" /></span>
            <span>{it.label}</span>
          </button>
        )}
      </div>
    </div>);

}

/* v3: OfflineBanner removed — the product uses no network (PRODUCT_CONTEXT §1). */

/* Snackbar — bottom toast with an optional action (Undo). Flutter: SnackBar.
   v3 addition: "moved to Trash · Undo" after a single deletion (BR-256, BR-263),
   save confirmations, export handoff. Sits above the bottom nav when `aboveNav`. */
function Snackbar({ children, action, aboveNav = false, style } = {}) {
  return (
    <div role="status" style={{
      position: 'absolute', left: 16, right: 16, bottom: aboveNav ? 'calc(var(--fab-nav-gap) + var(--fab-h) + 24px)' : 'calc(16px + env(safe-area-inset-bottom, 0px))', zIndex: 60,
      display: 'flex', alignItems: 'center', gap: 12, minHeight: 48, padding: '10px 16px',
      background: 'var(--memox-inverse-surface)', color: 'var(--memox-on-inverse-surface)',
      borderRadius: 'var(--memox-radius-md)', boxShadow: 'var(--memox-shadow-chrome)', fontSize: 14, lineHeight: 1.4,
      animation: 'memoxSheetIn 200ms cubic-bezier(0.2,0,0,1)', ...style
    }}>
      <span style={{ flex: 1, minWidth: 0 }}>{children}</span>
      {action ? <button style={{ background: 'transparent', border: 'none', color: 'var(--memox-inverse-primary)', fontWeight: 700, fontSize: 14, fontFamily: 'inherit', cursor: 'pointer', padding: '4px 8px', minHeight: 32 }}>{action}</button> : null}
    </div>);
}

/* Note — one calm line that states a product rule ("changes apply to future
   sessions", "recoverable for 30 days"). Info tone, never a warning. v3 addition. */
function Note({ icon = 'info', children, style } = {}) {
  return (
    <div style={{
      padding: '10px 12px', background: 'var(--memox-surface-muted)', border: 'var(--memox-border-ghost)',
      borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, textWrap: 'pretty',
      display: 'flex', gap: 8, alignItems: 'flex-start', ...style
    }}>
      <Ic name={icon} size="xs" color="var(--memox-on-surface-variant)" />
      <span style={{ flex: 1 }}>{children}</span>
    </div>);
}

/* OptionRow — radio row (title · description · trailing). Flutter: RadioListTile.
   v3 addition, used by deck create (algorithm), study entry (mode / direction),
   study options (new-card order) and reset. */
function OptionRow({ title, sub, trailing, selected = false, disabled = false, last = false, onClick } = {}) {
  return (
    <div role="radio" aria-checked={selected} aria-disabled={disabled || undefined} onClick={disabled ? undefined : onClick} style={{
      display: 'grid', gridTemplateColumns: '22px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', minHeight: 48,
      borderBottom: last ? 'none' : 'var(--memox-border-ghost)', cursor: disabled ? 'default' : 'pointer', opacity: disabled ? 'var(--memox-op-disabled)' : 1
    }}>
      <span style={{ width: 20, height: 20, borderRadius: 999, border: selected ? '6px solid var(--memox-primary)' : '2px solid var(--memox-outline)', boxSizing: 'border-box', background: 'var(--memox-surface-container-lowest)', flexShrink: 0 }} />
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{title}</div>
        {sub ? <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>{sub}</div> : null}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{trailing}</div>
    </div>);
}

/* ─────── Shared: SearchField — real mobile search input (not a desktop shortcut) ───────
   Replaces the old static-span + Cmd-K affordance. Renders as a tappable field with a
   leading search glyph, placeholder/value, and a trailing CLEAR (when filled) or VOICE
   (when empty) button — the two affordances a phone search actually offers. Height is the
   input token (52). Flutter: TextField(prefixIcon: search, suffixIcon: clear|mic). */
function SearchField({ placeholder = 'Search', value = '', active = false, onClick, style } = {}) {
  const filled = !!(value && value.length);
  return (
    <div role="search" onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: 8,
      height: 'var(--memox-size-input)', padding: '0 4px 0 16px',
      background: active ? 'var(--memox-surface-container-lowest)' : 'var(--memox-surface-container)',
      border: active ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)',
      borderRadius: 'var(--memox-radius-input)', cursor: 'text',
      transition: 'background 160ms var(--memox-ease-standard), border-color 160ms var(--memox-ease-standard)',
      ...style
    }}>
      <Ic name="search" size="sm" color={active ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)'} />
      <span style={{
        flex: 1, minWidth: 0, fontSize: 16, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        color: filled ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)'
      }}>
        {filled ? value : placeholder}
        {active &&
          <span style={{ display: 'inline-block', width: 2, height: 18, verticalAlign: 'text-bottom', marginLeft: 1, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />}
      </span>
      {/* v3: voice search removed — no audio/speech in the product. Clear shows only when filled. */}
      {filled ?
        <button className="icon-btn" aria-label="Clear search" style={{ width: 36, height: 36 }}>
          <Ic name="x" size="md" color="var(--memox-on-surface-variant)" />
        </button> : <span style={{ width: 12 }} />}
    </div>);

}

/* ─────── Shared: Badge — one count/status pill for every screen ───────
   Tonal by default (soft tint + colored label), or `solid` for a filled pill.
   Roomy padding + tabular nums fix the cramped ‘23due” rendering. Always feed it
   text WITH the unit (‘23 due”) so the space is part of the label.
   Flutter: a small Chip / Container(pill). */
function Badge({ children, tone = 'primary', solid = false, style } = {}) {
  const map = {
    primary: 'var(--memox-primary)',
    streak:  'var(--memox-streak)',
    mastery: 'var(--memox-mastery)',
    danger:  'var(--memox-error)',
    neutral: 'var(--memox-on-surface-variant)'
  };
  const c = map[tone] || map.primary;
  return (
    <span style={{
      height: 22, padding: '0 8px', borderRadius: 999, flexShrink: 0,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4,
      fontSize: 12, fontWeight: 700, lineHeight: 1, whiteSpace: 'nowrap', fontVariantNumeric: 'tabular-nums',
      color: solid ? 'var(--memox-on-primary)' : c,
      background: solid ? c : `color-mix(in srgb, ${c} 12%, transparent)`,
      ...style
    }}>{children}</span>);

}

/* ─────── Shared: Study top bar (close + mode badge + progress + counter) ─────── */
function StudyTopBar({ mode, accent = 'var(--memox-primary)', accentBg = 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', current, total, onClose }) {
  return (
    <div className="appbar" style={{ justifyContent: 'space-between' }}>
      <button className="icon-btn" onClick={onClose}><Ic name="x" size="md" /></button>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, flex: 1, margin: '0 4px' }}>
        <span style={{
          fontSize: 12, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase',
          color: accent, padding: '4px 8px', background: accentBg, borderRadius: 999
        }}>{mode}</span>
        <div style={{ flex: 1, height: 4, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
          <div style={{ height: '100%', width: `${current / total * 100}%`, background: accent, transition: 'width 200ms cubic-bezier(0.2,0,0,1)' }} />
        </div>
      </div>
      {/* paddingRight matches the close button's optical inset so the counter sits
          the same distance from the frame edge as the ✕ glyph on the left. */}
      <div style={{ fontSize: 12, fontWeight: 600, fontVariantNumeric: 'tabular-nums', color: 'var(--memox-on-surface-variant)', paddingRight: 8 }}>{current} / {total}</div>
    </div>);

}

/* ════════════════════════════════════════════════════════════════════════
   SHARED MOBILE LAYOUT PRIMITIVES
   One layout vocabulary for every screen, kept deliberately close to the
   Flutter widget tree so this mock translates 1:1 later. Spacing & bottom
   clearance are token-derived (see .app vars in index.html + LAYOUT.md) —
   never hand-tuned per screen.

   Conceptual mapping
     MobileScaffold → Scaffold + SafeArea
     ScreenHeader   → AppBar
     ScreenScroll   → Expanded( SingleChildScrollView )   (a.k.a. the body)
     BottomBar      → Scaffold.bottomNavigationBar / persistentFooterButtons
     Fab            → Scaffold.floatingActionButton  (the ONLY pinned content)
   Pinned/absolute positioning is reserved for true chrome only: FAB, bottom
   nav, sheets, scrims, toasts, modal overlays — never normal content.
   ════════════════════════════════════════════════════════════════════════ */

/* MobileScaffold — the column shell every screen shares.
   Children render in flow: header → scroll body → bottom bar. Pinned chrome
   (fab, overlay) layers on top via absolute positioning and is passed
   separately so it never interferes with the in-flow column.
     <MobileScaffold
        header={<ScreenHeader …/>}
        bottomBar={<BottomNav …/>}            // or a sticky footer
        fab={<Fab …/>}                         // optional, pinned
        overlay={sheetOrDialogNode}>           // optional, pinned full-bleed
       …scroll children…
     </MobileScaffold>
   `clearance` ('base' | 'fab' | 'fab-nav') is forwarded to the inner
   ScreenScroll so its bottom padding matches the pinned chrome present. */
function MobileScaffold({ header, children, bottomBar, fab, overlay, clearance = 'base', scrollProps = {}, style }) {
  return (
    <div className="app" style={style}>
      <StatusBar />
      {header}
      <ScreenScroll clearance={clearance} {...scrollProps}>{children}</ScreenScroll>
      {fab || null}
      {bottomBar || null}
      {overlay || null}
    </div>);
}

/* ScreenScroll — the single scrollable body. Flutter: Expanded(SingleChildScrollView).
   Horizontal gutter + bottom clearance come from tokens; `clearance` picks the
   variant so the last item always clears any pinned chrome:
     'base'    → nav / sticky footer / plain screen   (comfort gap only)
     'fab'     → screen has a FAB, no bottom nav
     'fab-nav' → screen has a FAB floating above the nav
   Extra className/style still compose (e.g. grid bodies, custom top padding). */
function ScreenScroll({ clearance = 'base', className = '', style, children, ...rest }) {
  const variant = clearance === 'fab' ? ' scroll-fab' : clearance === 'fab-nav' ? ' scroll-fab-nav' : '';
  return (
    <div className={('scroll' + variant + (className ? ' ' + className : '')).trim()} style={style} {...rest}>
      {children}
    </div>);
}

/* ScreenHeader — standard app bar. Flutter: AppBar(leading, title, actions).
   `leading`/`actions` are nodes (icon buttons); `large` switches to the taller
   title treatment. Keeps every screen's top chrome structurally identical. */
function ScreenHeader({ leading, title, actions, large = false, center = false, style, children }) {
  if (children) return <div className={'appbar' + (large ? ' appbar-lg' : '')} style={style}>{children}</div>;
  return (
    <div className={'appbar' + (large ? ' appbar-lg' : '')} style={style}>
      {leading || null}
      <div className="title" style={{ flex: 1, textAlign: center ? 'center' : 'left', fontSize: large ? 22 : undefined, fontWeight: 700, letterSpacing: '-0.3px' }}>{title}</div>
      {actions ? <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{actions}</div> : null}
    </div>);
}

/* BottomBar — in-flow bottom chrome wrapper for sticky footers / commit bars
   (Save, Done, Cancel/Confirm). Flutter: Scaffold.bottomNavigationBar.
   A sibling of the scroll — it never overlaps content, so the scroll only needs
   the 'base' comfort clearance. Carries the device safe-area inset. */
function BottomBar({ children, style }) {
  return (
    <div style={{
      flexShrink: 0, padding: '8px var(--screen-gutter) calc(16px + env(safe-area-inset-bottom, 0px))',
      borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)',
      display: 'flex', flexDirection: 'column', gap: 8, ...style
    }}>{children}</div>);
}

/* Fab — shared extended FloatingActionButton (pinned chrome). Flutter:
   FloatingActionButton.extended. Position/safe-area come from .fab tokens;
   pass `aboveNav` on screens that also show the bottom nav so it lifts clear. */
function Fab({ icon, label, onClick, aboveNav = false, style } = {}) {
  return (
    <button type="button" className={'fab' + (aboveNav ? ' fab-above-nav' : '')} onClick={onClick} aria-label={label || icon} title={label} style={style}>
      {icon ? <Ic name={icon} size="sm" color="var(--memox-on-primary)" /> : null}
    </button>);
}

/* ════════════════════════════════════════════════════════════════════════
   CONSOLIDATED PRIMITIVES  (2026-09 extraction pass)

   Every signature below ends `= {}`. These replaced zero-parameter local copies that
   some screens invoked bare — `Scrim()` rather than `<Scrim />` — and destructuring
   argument 0 of `undefined` throws, unmounting the whole screen. Keep the default when
   adding a primitive here.
   Each of these existed as 2–7 divergent per-screen copies. The canonical
   version below is the strongest-visual copy, not the simplest one; the
   divergences that were deliberate survive as variants, the accidental ones
   were dropped. Keyframes they depend on (memoxScrimIn / memoxDialogIn /
   memoxSheetIn / memoxSpin / memoxSkelPulse / memoxBlink) live once in
   components.css, which both this kit and components/Mx*.jsx load.
   ════════════════════════════════════════════════════════════════════════ */

/* Scrim — modal backdrop behind every dialog / sheet. Flutter: barrierColor.
   Was 6 copies: 5 hard-coded rgba(25,28,30,.45) — a LIGHT-mode scrim that
   stayed light-mode in Tokyo Nebula — and 1 correct token copy. The token
   copy wins; the raw ones were a dark-theme defect, not a design choice. */
function Scrim({ opacity = 45, zIndex = 50, onClick } = {}) {
  return <div onClick={onClick} style={{
    position: 'absolute', inset: 0, zIndex,
    background: `color-mix(in srgb, var(--memox-scrim) ${opacity}%, transparent)`,
    animation: 'memoxScrimIn 220ms ease'
  }} />;
}

/* Dialog — centered modal shell (+ its own scrim). Flutter: AlertDialog.
   Was 7 inline copies at maxWidth 300/320/340 on two different surfaces.
   Canonical: surface-container-high, radius 20, shadow-card. `size` keeps the
   one deliberate difference — onboarding's narrower confirm dialogs.
     sm 300 · md 320 · lg 340 (default) */
const DIALOG_W = { sm: 300, md: 320, lg: 340 };
function Dialog({ children, size = 'lg', scrim = true, onDismiss } = {}) {
  return (
    <>
      {scrim ? <Scrim onClick={onDismiss} /> : null}
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: '24px 20px', zIndex: 51, pointerEvents: 'none'
      }}>
        <div style={{
          width: '100%', maxWidth: DIALOG_W[size] || DIALOG_W.lg,
          background: 'var(--memox-surface-container-high)', color: 'var(--memox-on-surface)',
          borderRadius: 20, boxShadow: 'var(--memox-shadow-card)', pointerEvents: 'auto', overflow: 'hidden',
          animation: 'memoxDialogIn 200ms cubic-bezier(0.2,0,0,1)'
        }}>{children}</div>
      </div>
    </>);
}

/* BottomSheet — bottom-anchored modal surface. Flutter: showModalBottomSheet.
   Was 3 copies; the Tag-management one wins (it caps at 85% and flexes, so a
   long list scrolls inside instead of pushing the sheet off-screen).
   `grabber` is on by default — the drag affordance every sheet here showed. */
function BottomSheet({ children, grabber = true, scrim = true, maxHeight = '85%', onDismiss } = {}) {
  return (
    <>
      {scrim ? <Scrim onClick={onDismiss} /> : null}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 51,
        background: 'var(--memox-surface-container-high)', color: 'var(--memox-on-surface)',
        borderTopLeftRadius: 20, borderTopRightRadius: 20, boxShadow: 'var(--memox-shadow-chrome)',
        maxHeight, overflow: 'hidden', display: 'flex', flexDirection: 'column',
        animation: 'memoxSheetIn 260ms cubic-bezier(0.2,0,0,1)'
      }}>
        {grabber &&
          <div style={{ display: 'flex', justifyContent: 'center', padding: '8px 0 4px', flexShrink: 0 }}>
            <span style={{ width: 36, height: 4, borderRadius: 999, background: 'var(--memox-outline-variant)' }} />
          </div>}
        {children}
      </div>
    </>);
}

/* Skeleton — one loading-placeholder shape. Flutter: a shimmer/pulse Container.
   Was 7 `Skel` definitions (h 10/11/12, r 4/6) plus ~20 hand-rolled pulse spans.
   Canonical defaults h 12 / r 6 / op .5 — the majority spec. `shape="circle"`
   covers the round avatar/dot placeholders that were written out by hand. */
function Skeleton({ w = '100%', h = 12, op = 0.5, r = 6, shape, style } = {}) {
  const radius = shape === 'circle' ? 999 : r;
  return <span style={{
    display: 'block', width: w, height: h, borderRadius: radius, flexShrink: 0,
    background: 'var(--memox-surface-container-high)', opacity: op,
    animation: 'memoxSkelPulse 1.4s ease-in-out infinite', ...style
  }} />;
}

/* Spinner — indeterminate ring. Flutter: CircularProgressIndicator.
   Was 4 copies. Takes an ICON step name or a raw px number. */
function Spinner({ color = 'var(--memox-primary)', size = 'xs', style } = {}) {
  const px = ICON[size] || size;
  return <span role="progressbar" style={{
    display: 'inline-block', width: px, height: px, borderRadius: 999, flexShrink: 0,
    border: `2px solid ${color}`, borderTopColor: 'transparent',
    animation: 'memoxSpin 0.8s linear infinite', verticalAlign: 'middle', ...style
  }} />;
}

/* IconTile — tinted square holding a leading glyph. Flutter: Container + Icon.
   Was written inline ~40× as {width,height,borderRadius,color-mix tint}. The
   `.icon-tile` class already existed for the primary tint; `seed` overrides it
   for the per-folder/deck colors. Sizes are the three that actually shipped. */
const TILE = { sm: { box: 28, r: 8, ic: 'xs' }, md: { box: 36, r: 12, ic: 'sm' }, lg: { box: 44, r: 12, ic: 'sm' } };
function IconTile({ icon, size = 'lg', seed, tint = 12, style, children } = {}) {
  const t = TILE[size] || TILE.lg;
  const tinted = seed ? { background: `color-mix(in srgb, ${seed} ${tint}%, transparent)`, color: seed } : null;
  return (
    <div className={seed ? undefined : 'icon-tile'} style={{
      width: t.box, height: t.box, borderRadius: t.r, flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center', ...tinted, ...style
    }}>
      {children || (icon ? <Ic name={icon} size={t.ic} color={seed || 'var(--memox-primary)'} /> : null)}
    </div>);
}

/* ListRow — the leading-tile + title/subtitle + trailing row that backs Library,
   search results, tags and voices. Flutter: ListTile / InkWell row.
   Generalised from the Library-search `Row`; keeps the hairline divider and the
   truncation rules, which every copy had. Screen-specific rows that carry extra
   structure (deck mastery bar, flashcard status stripe) stay local by design. */
function ListRow({ icon, seed, leading, title, sub, trailing, last = false, tileSize = 'sm', onClick, style } = {}) {
  const lead = leading !== undefined ? leading : <IconTile icon={icon} seed={seed} size={tileSize} />;
  return (
    <div role={onClick ? 'button' : undefined} tabIndex={onClick ? 0 : undefined} onClick={onClick} style={{
      display: 'grid', gridTemplateColumns: 'auto 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', minHeight: 48,
      borderBottom: last ? 'none' : 'var(--memox-border-ghost)', cursor: onClick ? 'pointer' : 'default', ...style
    }}>
      {lead || <span />}
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{title}</div>
        {sub ? <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div> : null}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{trailing}</div>
    </div>);
}

/* EmptyState — action-led "nothing here yet" card. Flutter: a centered Column.
   Canonical is the Library version (64 tile / radius 20 / 20px title), which is
   the most considered of the copies; `compact` is the smaller in-card variant. */
function EmptyState({ icon = 'inbox', title, body, action, footnote, compact = false, style } = {}) {
  const box = compact ? 52 : 64;
  return (
    <div className="card" style={{ padding: compact ? '32px 24px' : '44px 24px 32px', textAlign: 'center', marginTop: 8, ...style }}>
      <div style={{
        width: box, height: box, borderRadius: compact ? 16 : 20, marginBottom: 16,
        background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center'
      }}>
        <Ic name={icon} size={compact ? 'md' : 'lg'} color="var(--memox-primary)" />
      </div>
      <div style={{ fontSize: compact ? 16 : 20, fontWeight: 700, letterSpacing: '-0.3px', marginBottom: 8 }}>{title}</div>
      {body ? <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: action ? 20 : 0, padding: '0 4px' }}>{body}</div> : null}
      {action}
      {footnote ?
        <div style={{
          marginTop: 20, padding: '10px 12px', background: 'var(--memox-surface-muted)',
          borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface-variant)',
          lineHeight: 1.5, textAlign: 'left', display: 'flex', gap: 8, alignItems: 'flex-start'
        }}>
          <Ic name="info" size="xs" color="var(--memox-on-surface-variant)" />
          <span>{footnote}</span>
        </div> : null}
    </div>);
}

/* ErrorState — inline data-load failure + Retry. Flutter: same Column, error tone.
   Local-first voice: reassure that nothing was lost, then offer the retry. */
function ErrorState({ icon = 'cloud-off', title, body, action, style } = {}) {
  return (
    <div className="card" style={{ padding: '40px 24px', textAlign: 'center', marginTop: 8, ...style }}>
      <div style={{
        width: 52, height: 52, borderRadius: 16, marginBottom: 16,
        background: 'var(--memox-danger-soft)', color: 'var(--memox-error)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center'
      }}>
        <Ic name={icon} size="md" color="var(--memox-error)" />
      </div>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>{title}</div>
      {body ? <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: action ? 16 : 0 }}>{body}</div> : null}
      {action !== undefined ? action :
        <button className="pill-btn primary" style={{ fontSize: 14 }}>
          <Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />Retry
        </button>}
    </div>);
}

/* Toggle — on/off switch. Flutter: Switch (M3).
   Two sizes shipped (44×26 in settings, 46×28 in the docs panel); 44×26 is the
   one every real screen uses, so it is the contract and the doc card follows it. */
function Toggle({ on = false, disabled = false, onChange, style } = {}) {
  return (
    <span role="switch" aria-checked={on} aria-disabled={disabled || undefined}
      tabIndex={disabled ? -1 : 0} onClick={disabled ? undefined : onChange}
      style={{
        display: 'inline-block', position: 'relative', width: 44, height: 26, borderRadius: 999, flexShrink: 0,
        background: on ? 'var(--memox-primary)' : 'var(--memox-surface-container-highest)',
        opacity: disabled ? 'var(--memox-op-disabled)' : 1,
        cursor: disabled ? 'default' : 'pointer',
        transition: 'background 160ms var(--memox-ease-standard)', ...style
      }}>
      <span style={{
        position: 'absolute', top: 3, left: on ? 21 : 3, width: 20, height: 20, borderRadius: 999,
        background: 'var(--memox-surface-bright)', boxShadow: 'var(--memox-shadow-soft)',
        transition: 'left 160ms var(--memox-ease-standard)'
      }} />
    </span>);
}

/* TextField — the kit's static text-input mock. Flutter: TextField.
   Filled surface + ghost border, 1px primary border on focus, error tone below.
   `rows` makes it the multi-line variant; `minHeight 40` is the compact
   optional-field size the form screens use, 52 (--memox-size-input) the default. */
function TextField({ value, placeholder, focused = false, error, disabled = false, multiline = false, trailing, leading, style } = {}) {
  const border = error ? '1px solid var(--memox-error)' : focused ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)';
  return (
    <div>
      <div style={{
        display: 'flex', alignItems: multiline ? 'flex-start' : 'center', gap: 8,
        minHeight: multiline ? 40 : 'var(--memox-size-input)', padding: multiline ? '8px 12px' : '0 12px',
        background: focused ? 'var(--memox-surface-container-lowest)' : 'var(--memox-surface-muted)', border, borderRadius: 'var(--memox-radius-input)',
        opacity: disabled ? 'var(--memox-op-disabled)' : 1,
        fontSize: 14, lineHeight: 1.5, ...style
      }}>
        {leading}
        <span style={{
          flex: 1, minWidth: 0, color: value ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)',
          whiteSpace: multiline ? 'normal' : 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'
        }}>
          {value || placeholder}
          {focused && <span style={{ display: 'inline-block', width: 2, height: 16, verticalAlign: 'text-bottom', marginLeft: 1, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />}
        </span>
        {trailing}
      </div>
      {error ?
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '4px 4px 0', fontSize: 12, color: 'var(--memox-error)' }}>
          <Ic name="alert-circle" size="xs" color="var(--memox-error)" />{error}
        </div> : null}
    </div>);
}

/* StatusBadge — card-lifecycle marker: new ▸ learning ▸ reviewing ▸ mastered.
   Distinct from Badge (which counts things): this one names a state, so the
   token map and the labels belong to the component, not to each screen.
   `dot` is the bare 8px indicator used inside dense flashcard rows. */
const STATUS = {
  new:       { color: 'var(--memox-status-new)',       label: 'New' },
  learning:  { color: 'var(--memox-status-learning)',  label: 'Learning' },
  reviewing: { color: 'var(--memox-status-reviewing)', label: 'Reviewing' },
  mastered:  { color: 'var(--memox-status-mastered)',  label: 'Mastered' }
};
function StatusBadge({ status = 'new', dot = false, label, style } = {}) {
  const s = STATUS[status] || STATUS.new;
  if (dot) return <span className="status-dot" style={{ background: s.color, ...style }} />;
  return (
    <span style={{
      height: 22, padding: '0 8px 0 6px', borderRadius: 999, flexShrink: 0,
      display: 'inline-flex', alignItems: 'center', gap: 4,
      fontSize: 12, fontWeight: 700, lineHeight: 1, whiteSpace: 'nowrap',
      color: s.color, background: `color-mix(in srgb, ${s.color} 12%, transparent)`, ...style
    }}>
      <span className="status-dot" style={{ background: s.color, width: 6, height: 6 }} />
      {label || s.label}
    </span>);
}

Object.assign(window, {
  StatusBar, masteryColor, Ic, ICON, Breadcrumb, BottomNav, SearchField, Badge, StudyTopBar, Snackbar, Note, OptionRow,
  MobileScaffold, ScreenScroll, ScreenHeader, BottomBar, Fab,
  Scrim, Dialog, BottomSheet, Skeleton, Spinner, IconTile, ListRow, EmptyState, ErrorState, Toggle, TextField, StatusBadge, STATUS
});
})();
