import React from 'react';

/**
 * A row in a list.
 *
 * Deliberately generic. It takes a string title and arbitrary leading/trailing
 * nodes, not a deck or a card: the moment a shared row knows an entity, every test
 * that touches it pulls the domain in behind it, and the row stops being usable by
 * the next feature that has a different entity and the same layout. `DeckTile` and
 * `CardTile` are built ON this, in their own features.
 */
export function MxListTile({
  title,
  subtitle,
  leading,
  trailing,
  onTap,
  isEnabled = true,
  isSelected = false,
  className = '',
  ...rest
}) {
  const isInteractive = isEnabled && onTap != null;

  const classes = [
    'mx-list-tile',
    isInteractive ? 'mx-list-tile--interactive mx-focus-ring' : '',
    isSelected ? 'mx-list-tile--selected' : '',
    !isEnabled ? 'mx-list-tile--disabled' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  const body = (
    <>
      {leading ? <span className="mx-list-tile__leading">{leading}</span> : null}
      <span className="mx-list-tile__text">
        <span className="mx-list-tile__title mx-type-body-large">{title}</span>
        {subtitle ? (
          <span className="mx-list-tile__subtitle mx-type-body-medium">{subtitle}</span>
        ) : null}
      </span>
      {trailing ? <span className="mx-list-tile__trailing">{trailing}</span> : null}
    </>
  );

  // A row that does nothing is not a button. Rendering it as one puts a tab stop
  // in the focus order that answers nothing when the user presses Enter, which is
  // worse than not being reachable at all.
  if (!isInteractive) {
    return (
      <div className={classes} aria-disabled={!isEnabled || undefined} {...rest}>
        {body}
      </div>
    );
  }

  return (
    <button
      type="button"
      className={classes}
      onClick={onTap}
      // `isSelected` is a visual state AND an announced one. Left to colour alone
      // it says nothing to a screen reader and nothing to a colour-blind user.
      aria-current={isSelected ? 'true' : undefined}
      {...rest}
    >
      {body}
    </button>
  );
}

export default MxListTile;
