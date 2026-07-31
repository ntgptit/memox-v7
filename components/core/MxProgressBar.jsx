import React from 'react';

/**
 * How far through something the user is.
 *
 * Determinate by default and indeterminate only when there is genuinely no total
 * — `value: null`. The two say different things and are not interchangeable: a
 * bar that slides forever tells the user "this is running", and a bar at 40% tells
 * them "this is nearly half done". Faking the second with the first is how a
 * progress indicator becomes decoration nobody trusts.
 *
 * `semanticLabel` is required for the same reason `MxLoadingState` requires one: a
 * bare bar announces nothing at all, so the user is told neither what is
 * progressing nor when it stops.
 *
 * The fill is `focus-ring`, not `primary`. Material's default for an indicator is
 * `colorScheme.primary`, and measured against the surface it sits on dark
 * `primary` scores 2.81:1 — under the 3.0 floor a graphic needs. That value was
 * never chosen for this job: it is held at a luminance that keeps a filled button
 * from becoming the brightest thing on a navy page, which is the opposite of what
 * an indicator wants.
 */
export function MxProgressBar({
  value,
  semanticLabel,
  label,
  valueLabel,
  className = '',
  ...rest
}) {
  const isIndeterminate = value == null;
  // Clamped rather than trusted. A caller that computes 21/20 gets a full bar
  // instead of one that overflows its track and paints outside the radius.
  const ratio = isIndeterminate ? 0 : Math.min(1, Math.max(0, value));

  return (
    <div
      className={[
        'mx-progress-bar',
        isIndeterminate ? 'mx-progress-bar--indeterminate' : '',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      {...rest}
    >
      {label || valueLabel ? (
        <div className="mx-progress-bar__header">
          {label ? <span className="mx-type-label-large">{label}</span> : null}
          {/* Already-localized and already formatted — "3 of 20", not a fraction
              this component invents in one language. */}
          {valueLabel ? <span className="mx-type-label-medium">{valueLabel}</span> : null}
        </div>
      ) : null}
      <div
        className="mx-progress-bar__track"
        role="progressbar"
        aria-label={semanticLabel}
        // Omitted entirely while indeterminate. Reporting 0 would have the reader
        // announce "0 percent" for something that has no percentage.
        aria-valuenow={isIndeterminate ? undefined : Math.round(ratio * 100)}
        aria-valuemin={isIndeterminate ? undefined : 0}
        aria-valuemax={isIndeterminate ? undefined : 100}
        aria-valuetext={isIndeterminate ? undefined : valueLabel}
      >
        <div
          className="mx-progress-bar__indicator"
          style={isIndeterminate ? undefined : { width: `${ratio * 100}%` }}
        />
      </div>
    </div>
  );
}

export default MxProgressBar;
