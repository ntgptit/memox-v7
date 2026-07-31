const { MxTextField, MxActionButton, MxIcon } = window.MemoxDesignSystem_3a620f;

/**
 * The one deck form, used for create-root, create-sub-deck and rename. The
 * study-mode section appears only for a root deck (BR-06) and nothing is
 * preselected (BR-11) — a dropdown would have to show a default.
 */
function DeckFormSheet({ title, submitLabel, isSchedulerRequired, onSubmit, onCancel }) {
  const [name, setName] = React.useState('');
  const [scheduler, setScheduler] = React.useState(null);
  const [error, setError] = React.useState(null);

  function submit() {
    if (!name.trim()) { setError('Enter a name'); return; }
    if (isSchedulerRequired && !scheduler) { setError(null); setScheduler('__missing'); return; }
    onSubmit(name);
  }

  return (
    <div className="mx-scrim mx-scrim--bottom" onClick={onCancel}>
      <div className="mx-sheet" onClick={(e) => e.stopPropagation()} style={{ padding: '0 var(--space-lg) var(--space-lg)' }}>
        <div className="mx-sheet__handle" />
        <p style={{ fontSize: 'var(--text-title-md)', letterSpacing: 'var(--tracking-title-md)', fontWeight: 600, margin: '0 0 var(--space-lg)' }}>{title}</p>
        <MxTextField label="Deck name" value={name} onChange={(v) => { setName(v); setError(null); }} maxLength={200} errorText={error} onSurface autoFocus />
        {isSchedulerRequired ? (
          <div style={{ marginTop: 'var(--space-md)' }}>
            <p style={{ fontSize: 'var(--text-label-lg)', fontWeight: 600, margin: '0 0 var(--space-sm)' }}>Study mode</p>
            <SchedulerChoice label="Eight boxes" description="Two answers: forgotten or remembered." value="eight_box" selected={scheduler} onSelect={setScheduler} />
            <SchedulerChoice label="SM-2" description="Four answers: again, hard, good, easy." value="sm2" selected={scheduler} onSelect={setScheduler} />
            <p style={{ fontSize: 'var(--text-body-sm)', lineHeight: 'var(--leading-body-sm)', color: 'var(--color-text-secondary)', margin: 'var(--space-sm) 0 0' }}>
              The study mode locks after the first review. Changing it later needs a progress reset.
            </p>
            {scheduler === '__missing' ? <p style={{ fontSize: 'var(--text-body-sm)', color: 'var(--color-danger)', margin: '4px 0 0' }}>Choose a study mode</p> : null}
          </div>
        ) : null}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-sm)', marginTop: 'var(--space-xl)' }}>
          <MxActionButton label="Cancel" variant="secondary" onClick={onCancel} />
          <MxActionButton label={submitLabel} onClick={submit} />
        </div>
      </div>
    </div>
  );
}

/** Radio rows rather than a dropdown: whatever a closed dropdown shows becomes a default. */
function SchedulerChoice({ label, description, value, selected, onSelect }) {
  const isOn = selected === value;
  return (
    <button type="button" onClick={() => onSelect(value)} style={{ display: 'flex', gap: 'var(--space-md)', width: '100%', alignItems: 'flex-start', background: 'none', border: 0, padding: 'var(--space-sm) 0', cursor: 'pointer', textAlign: 'left', font: 'inherit' }}>
      <MxIcon name={isOn ? 'radio_button_checked' : 'radio_button_unchecked'} filled color={isOn ? 'var(--color-primary)' : 'var(--color-text-secondary)'} />
      <span>
        <span style={{ display: 'block', fontSize: 'var(--text-body-lg)' }}>{label}</span>
        <span style={{ display: 'block', fontSize: 'var(--text-body-sm)', color: 'var(--color-text-secondary)' }}>{description}</span>
      </span>
    </button>
  );
}

Object.assign(window, { DeckFormSheet, SchedulerChoice });
