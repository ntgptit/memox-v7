import React from 'react';

import MxIcon from '../core/MxIcon.jsx';

/**
 * The app's bottom navigation bar.
 *
 * Render-only, and deliberately ignorant. It takes a selected index, a callback and
 * a list of destinations; it does not know the router, does not know what a deck or
 * a review is, and never navigates. A shared component that knew the route table
 * would drag routing into every test that touches it, and it would stop being
 * usable by any shell with a different set of destinations.
 *
 * The row is capped at 120px PER DESTINATION rather than at a fixed width, so the
 * cap disarms itself: an even split puts two destinations at the quarter and
 * three-quarter marks with a void between them that reads as a missing tab, while
 * at four destinations the row wants more width than a phone has and the constraint
 * stops applying — which is the arrangement the even split was designed for. A
 * fixed maximum would have to be revisited every time a tab is added.
 *
 * The bar paints the page colour, like the app bar above it, so narrowing it leaves
 * no band edge to notice.
 */
export function MxNavigationBar({
  selectedIndex,
  onDestinationSelected,
  destinations,
  semanticLabel,
  className = '',
  ...rest
}) {
  if (destinations.length < 2 && typeof console !== 'undefined') {
    console.warn('MxNavigationBar: a navigation bar needs at least two destinations.');
  }

  return (
    <nav className={`mx-nav-bar ${className}`.trim()} aria-label={semanticLabel} {...rest}>
      <div
        className="mx-nav-bar__row"
        style={{ '--mx-nav-destination-count': destinations.length }}
      >
        {destinations.map((destination, index) => {
          // Out-of-range values are the caller's bug and are not silently clamped:
          // a bar showing tab 0 when the router says 3 is a navigation bug wearing
          // a working UI.
          const isSelected = index === selectedIndex;

          return (
            <button
              key={destination.key ?? destination.label}
              type="button"
              className={[
                'mx-nav-bar__destination',
                isSelected ? 'mx-nav-bar__destination--selected' : '',
                'mx-focus-ring',
              ]
                .filter(Boolean)
                .join(' ')}
              aria-current={isSelected ? 'page' : undefined}
              onClick={() => onDestinationSelected(index)}
            >
              <span className="mx-nav-bar__indicator">
                <MxIcon
                  name={isSelected ? destination.selectedIcon ?? destination.icon : destination.icon}
                  size="md"
                />
              </span>
              {/* Labels always visible, on every destination. The M3 default hides
                  the unselected ones, which leaves three unlabelled icons and one
                  labelled — and makes selection readable only as a colour
                  difference, which is exactly what an accessibility review
                  rejects. */}
              <span className="mx-nav-bar__label mx-type-label-small">{destination.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}

export default MxNavigationBar;
