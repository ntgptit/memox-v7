/* MemoX Mobile v3 — FlashcardEditScreen · MAIN  (A9 · Card editor, edit)
   Product corrections vs v1: mic/speaker removed (no audio); the history strip
   no longer shows a recall % (no accuracy anywhere, BR-243) — it shows answers,
   lapses and the due time and links to the card detail; the deck chip is not a
   picker; "Delete" is "Move to Trash", recoverable, without the danger-zone tone
   (BR-256, BR-266); flag toggle added; discard-changes confirm added. Form kept.
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     FlashcardEditScreen/
       FlashcardEditScreen.jsx  ← shared edit form + helpers, rendered from a flag set
       states/                  ← one file per state in window.MemoXStates.FlashcardEdit

   Like Create, this is ONE form with flag-driven states, so each state file just
   declares its flags:
     window.MemoXStates.FlashcardEdit.<name> = () =>
       ({ loading, loadError, validationErr, saving, saveFailed, delConfirm })
   The MAIN file derives `valid` / `back` from those, renders the single form, swaps
   to the full-screen load-error layout when loadError, and adds the delete dialog
   when delConfirm. Editing one state's file never touches the others. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar } = window;

const FRONT = '공부하다';
const example = '도서관에서 친구와 같이 한국어를 공부해요.';
const hint = 'Hán Việt: 工夫 – công phu';
const pron = '[공부하다] gong-bu-ha-da';
const tags = ['hay nhầm', 'TOPIK I', 'động từ'];

/* white-on-primary default: these spinners sit inside filled CTAs. */
const Spinner = (p) => <window.Spinner color="#fff" {...p} />;

const Skel = window.Skeleton;

const Dialog = window.Dialog;

const FieldHeader = ({ label, required, count, max, loading }) =>
  <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '0 4px 4px' }}>
    <div style={{ display: 'inline-flex', alignItems: 'baseline', gap: 4 }}>
      <span className="ov">{label}</span>
      {required && <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-primary)', letterSpacing: 0.3 }}>Required</span>}
    </div>
    {count != null && !loading && <span style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.2, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{count} / {max}</span>}
  </div>;

const OptionalField = ({ label, icon, value, trailing }) =>
  <div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px 4px' }}>
      <Ic name={icon} size="xs" color="var(--memox-on-surface-variant)" />
      <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>{label}</span>
      <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', opacity: 0.55, fontWeight: 500 }}>· optional</span>
    </div>
    <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', padding: '8px 12px', minHeight: 40, fontSize: 14, color: 'var(--memox-on-surface)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, lineHeight: 1.45 }}>
      <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{value}</span>
      {trailing}
    </div>
  </div>;

/* ════════════ SCREEN ════════════ */
function FlashcardEditScreenV3({ go, state = 'loaded' }) {
  const States = (window.MemoXStates && window.MemoXStates.FlashcardEdit) || {};
  const mod = States[state] || States.loaded;
  const f = (mod ? mod() : {}) || {};
  const { loading = false, loadError = false, notFound = false, validationErr = false, saving = false, saveFailed = false, delConfirm = false, discard = false, flagged = true } = f;
  const valid = !loading && !loadError && !validationErr;
  const back = validationErr ? '' : 'học, học tập';
  const { Note, EmptyState } = window;

  /* Card gone — moved to Trash from another area while the editor was open (A9). */
  if (notFound) {
    return (
      <div className="app">
        <StatusBar />
        <div className="appbar" style={{ justifyContent: 'space-between' }}>
          <button className="icon-btn" onClick={() => go('cards')} aria-label="Close"><Ic name="x" size="md" /></button>
          <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Edit card</div>
        </div>
        <div className="scroll">
          <EmptyState icon="search-x" title="This card is no longer here" body="It was moved to Trash while you were editing. Your unsaved changes were not applied; the card can still be restored from Trash."
            action={<div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}><button className="pill-btn primary" style={{ fontSize: 14 }}>Back to deck</button><button className="pill-btn outline" style={{ fontSize: 14 }}>Open Trash</button></div>} />
        </div>
      </div>);
  }

  /* Load error replaces the entire body. */
  if (loadError) {
    return (
      <div className="app">
        <StatusBar />
        <div className="appbar" style={{ justifyContent: 'space-between' }}>
          <button className="icon-btn" onClick={() => go('cards')}>
            <Ic name="x" size="md" />
          </button>
          <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Edit card</div>
        </div>
        <div className="scroll" style={{ padding: '24px 24px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="card" style={{ padding: '36px 24px', textAlign: 'center', width: '100%' }}>
            <div style={{ width: 52, height: 52, borderRadius: 16, background: 'var(--memox-danger-soft)', color: 'var(--memox-error)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
              <Ic name="cloud-off" size="md" color="var(--memox-error)" />
            </div>
            <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>Couldn't load this card</div>
            <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16 }}>
              Your data is safe on this device. Try again in a moment.
            </div>
            <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
              <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Back to deck</button>
              <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
                <Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />
                Retry
              </button>
            </div>
          </div>
        </div>
      </div>);
  }

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('cards')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Edit card</div>
        <button className="icon-btn" aria-pressed={flagged} aria-label={flagged ? 'Remove flag' : 'Flag this card'} title={flagged ? 'Flagged' : 'Flag'}>
          <Ic name="flag" size="sm" color={flagged ? 'var(--memox-streak)' : 'var(--memox-on-surface-variant)'} />
        </button>
        <button className="pill-btn primary" disabled={!valid || saving} style={{ height: 32, padding: '0 16px', borderRadius: 'var(--memox-radius-sm)', fontSize: 12, gap: 4, opacity: !valid || saving ? 0.45 : 1, pointerEvents: !valid || saving ? 'none' : 'auto' }}>
          {saving ? <><Spinner size="xs" /> Saving…</> : 'Save'}
        </button>
      </div>

      <Breadcrumb segments={[{ label: 'Library' }, { label: '한국어 TOPIK I · Từ vựng' }, { label: 'Động từ · 동사' }, { label: 'Edit' }]} />

      <div className="scroll">

        {/* Card history strip */}
        {!loading &&
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', marginBottom: 16, fontSize: 12 }}>
            <Ic name="clock" size="xs" color="var(--memox-on-surface-variant)" />
            <span style={{ flex: 1, color: 'var(--memox-on-surface-variant)' }}>
              <span style={{ color: 'var(--memox-on-surface)', fontWeight: 600 }}>Reviewing</span> ·
              <span style={{ fontVariantNumeric: 'tabular-nums' }}> 7 answers · 1 lapse · due 4 Oct</span>
            </span>
            <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'var(--memox-primary)', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              Details
              <Ic name="chevron-right" size="xs" color="var(--memox-primary)" />
            </button>
          </div>}

        {/* Deck destination */}
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '4px 12px 4px 8px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 999, fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
          <span style={{ width: 22, height: 22, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name="layers" size="xs" color="var(--memox-primary)" />
          </span>
          <span>Động từ · 동사</span>
        </div>

        <div className="ov" style={{ padding: '0 4px 8px', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--memox-primary)' }} />
          Required
        </div>

        {/* Front */}
        <FieldHeader label="Front · Term" required count={loading ? null : FRONT.length} max={60} loading={loading} />
        <div className="card" style={{ padding: '16px 16px', minHeight: 66, display: 'flex', alignItems: 'center', position: 'relative', background: 'var(--memox-surface-container-lowest)', marginBottom: 16 }}>
          {loading ? <Skel w={120} h={22} /> :
            <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', lineHeight: 1.2 }}>{FRONT}</div>}
        </div>

        {/* Back */}
        <FieldHeader label="Back · Meaning" required count={loading ? null : back.length} max={240} loading={loading} />
        <div className="card" style={{ padding: '12px 16px', minHeight: 76, background: 'var(--memox-surface-container-lowest)', borderColor: validationErr ? 'var(--memox-error)' : undefined, borderWidth: validationErr ? 1 : undefined, borderStyle: validationErr ? 'solid' : undefined, display: 'flex', alignItems: loading || !back ? 'center' : 'flex-start', marginBottom: validationErr ? 8 : 16 }}>
          {loading ?
            <div style={{ width: '100%' }}>
              <Skel w="80%" h={13} />
              <div style={{ height: 6 }} />
              <Skel w="55%" h={13} op={0.35} />
            </div> :
            back ?
              <div style={{ fontSize: 16, fontWeight: 500, lineHeight: 1.45 }}>{back}</div> :
              <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', opacity: 0.65, lineHeight: 1.5 }}>
                English, Vietnamese, or both — comma-separated reads cleanest.
              </div>}
        </div>
        {validationErr &&
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px', color: 'var(--memox-error)', fontSize: 12, fontWeight: 600, marginBottom: 16 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <span>Add a meaning so this card can be answered.</span>
          </div>}

        {/* Optional details */}
        <div className="ov" style={{ padding: '0 4px 8px' }}>Optional details</div>
        {loading ?
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 16 }}>
            {[0, 1, 2].map((i) =>
              <div key={i} style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', padding: '12px 16px' }}>
                <Skel w={90} h={9} op={0.4} />
                <div style={{ height: 8 }} />
                <Skel w={i === 1 ? '70%' : '60%'} h={12} />
              </div>
            )}
          </div> :
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 16 }}>
            <OptionalField icon="message-square" label="Example sentence" value={example} />
            <OptionalField icon="lightbulb" label="Hint" value={hint} />
            <OptionalField icon="type" label="Pronunciation" value={pron} />
          </div>}

        {/* Tags */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '0 4px 8px' }}>
          <Ic name="tag" size="xs" color="var(--memox-on-surface-variant)" />
          <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>Tags</span>
          <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', opacity: 0.55, fontWeight: 500 }}>· optional</span>
        </div>
        {loading ?
          <div style={{ display: 'flex', gap: 4, marginBottom: 24 }}>
            <Skel w={70} h={26} />
            <Skel w={56} h={26} />
            <Skel w={64} h={26} />
          </div> :
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginBottom: 24 }}>
            {tags.map((t) =>
              <span key={t} style={{ height: 28, padding: '0 8px 0 12px', background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', borderRadius: 999, fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                {t}
                <Ic name="x" size="xs" color="var(--memox-primary)" />
              </span>
            )}
            <button style={{ height: 28, padding: '0 12px', background: 'transparent', color: 'var(--memox-on-surface-variant)', border: '1px dashed var(--memox-outline-variant)', borderRadius: 999, fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 4, fontFamily: 'inherit', cursor: 'pointer' }}>
              <Ic name="plus" size="xs" color="var(--memox-on-surface-variant)" />
              Add tag
            </button>
          </div>}

        <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: '8px 4px 24px' }} />

        {/* Move to Trash — recoverable, so no danger-zone tone (BR-256, BR-266). Editing never changes schedule or history (BR-10). */}
        <div className="ov" style={{ padding: '0 4px 8px' }}>More</div>
        <div className="card" style={{ padding: 16, marginBottom: 16 }}>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>Move this card to Trash</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 12 }}>
            Leaves <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>Động từ · 동사</strong> and can be restored from Trash for 30 days, schedule and history included.
          </div>
          <button disabled={loading} className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8, opacity: loading ? 0.45 : 1 }}>
            <Ic name="trash-2" size="xs" color="var(--memox-on-surface)" />
            Move to Trash
          </button>
        </div>
      </div>

      {/* Save bar */}
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {saveFailed &&
          <div style={{ padding: '8px 12px', background: 'var(--memox-danger-soft)', border: '1px solid var(--memox-danger-border)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'flex-start' }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <div style={{ flex: 1, fontSize: 12, lineHeight: 1.45 }}>
              <strong style={{ fontWeight: 700 }}>Couldn't save changes.</strong>{' '}
              <span style={{ color: 'var(--memox-on-surface-variant)' }}>Nothing was lost. Tap Save to try again.</span>
            </div>
          </div>}
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 12, fontSize: 14, flexShrink: 0 }}>Cancel</button>
          <button className="pill-btn primary" disabled={!valid || saving} style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: !valid || saving ? 0.45 : 1, pointerEvents: !valid || saving ? 'none' : 'auto' }}>
            {saving ? <><Spinner size="xs" /> Saving changes…</> :
              saveFailed ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" /> Retry save</> :
              <><Ic name="check" size="xs" color="var(--memox-on-primary)" /> Save changes</>}
          </button>
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>
          {loading ? 'Loading card…' :
            validationErr ? 'Add the missing field to enable save.' :
            saving ? 'Saving to this device…' :
            'Editing content never changes the schedule or history.'}
        </div>
      </div>

      {/* Move-to-Trash confirm (A8): plain tone, recoverable. */}
      {delConfirm &&
        <Dialog>
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <div style={{ width: 34, height: 34, borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Ic name="trash-2" size="xs" color="var(--memox-on-surface-variant)" />
              </div>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>Move this card to Trash?</div>
            </div>
            <div style={{ padding: '12px 16px', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', border: 'var(--memox-border-ghost)', marginTop: 4 }}>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>{FRONT}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>{back}</div>
            </div>
            <Note icon="history" style={{ marginTop: 12 }}>Recoverable for 30 days with its 7 answers of history. Other cards are unaffected.</Note>
          </div>
          <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
            <button className="pill-btn primary" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
              <Ic name="trash-2" size="xs" color="var(--memox-on-primary)" />
              Move to Trash
            </button>
          </div>
        </Dialog>}

      {/* Discard changes (A9) */}
      {discard &&
        <Dialog size="md">
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Discard changes?</div>
            <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55 }}>You edited the meaning and the hint. Leaving now keeps the card as it was saved.</div>
          </div>
          <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Keep editing</button>
            <button className="pill-btn primary" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Discard</button>
          </div>
        </Dialog>}

    </div>);
}

Object.assign(window, { FlashcardEditScreenV3 });
})();
