import React from 'react';

/**
 * A determinate progress bar. Added in the redesign, where progress is the thing
 * the interface is organised around: a learner's question is "how far am I",
 * and a count of cards answers it only after arithmetic.
 *
 * It draws in its own colour family rather than the accent, so a bar never
 * competes with the button next to it, and turns green at 100% — the one place
 * the interface is allowed to congratulate anybody.
 *
 * `isLabelPainted={false}` hides the caption and keeps `aria-label`. The deck
 * hero's collapsed state wants a bare rule under its figure line; a caller that
 * dropped the strings to get one would ship a progressbar with no accessible
 * name at all. What is painted and what is announced are two decisions.
 */
export function MxProgressBar({ value, label, valueLabel, size = 'md', shape = 'pill', tone = 'progress', isLabelPainted = true }) {
  const pct = Math.max(0, Math.min(1, value));
  const complete = pct >= 1;
  const fill = tone === 'streak' ? 'var(--color-streak)' : (complete ? 'var(--color-progress-complete)' : 'var(--color-progress-fill)');
  return (
    <div className={`mx-progress mx-progress--${size} mx-progress--${shape}`} role="progressbar" aria-valuenow={Math.round(pct * 100)} aria-valuemin={0} aria-valuemax={100} aria-label={label}>
      {(isLabelPainted && (label || valueLabel)) ? (
        <div className="mx-progress__head">
          <span>{label}</span>
          <span className="mx-progress__value" style={complete ? { color: 'var(--color-progress-complete)' } : undefined}>{valueLabel}</span>
        </div>
      ) : null}
      <div className="mx-progress__track">
        <div className="mx-progress__fill" style={{ width: `${pct * 100}%`, background: fill }} />
      </div>
    </div>
  );
}
