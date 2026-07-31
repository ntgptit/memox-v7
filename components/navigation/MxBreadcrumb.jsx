import React from 'react';

import MxIcon from '../core/MxIcon.jsx';

/**
 * The path from the top of a hierarchy down to where the user is now.
 *
 * Why this is not one of the others. `MxNavigationBar` switches between siblings
 * at a fixed top level; a breadcrumb moves UP an arbitrary number of levels.
 * `MxPillButton` is one of N views of the same content — a set, not a sequence,
 * and it has a selected state where a path has a last element. `MxListTile` is a
 * row.
 *
 * It scrolls horizontally and therefore cannot overflow. A path can be ten deep
 * and a 320-wide screen at a 2× text scale fits about one and a half names. The
 * alternatives were both worse: wrapping turns a deep path into five lines of
 * chrome above the content it is meant to help you scan, and collapsing the middle
 * behind an ellipsis hides exactly the steps a user goes to a breadcrumb to find.
 * Scrolling hides nothing and costs nothing when the path is short.
 */
export function MxBreadcrumb({ items, semanticLabel, className = '', ...rest }) {
  // An empty list renders nothing at all — not an empty bar. A path with one
  // element says only "you are here", which the title already said, so a caller
  // with nothing above the current step should not build this.
  if (!items || items.length === 0) return null;

  return (
    <nav
      className={`mx-breadcrumb ${className}`.trim()}
      // Names the strip — "deck path", not the path itself. The steps stay their
      // own nodes underneath, so a reader announces the group and then each step
      // as its own control rather than reading one run-on string.
      aria-label={semanticLabel}
      {...rest}
    >
      {items.map((item, index) => {
        // Quiet when there is nowhere to go — derived from `onTap`, NOT from the
        // position in the list. Keying it on "is this the last one" is the same
        // thing only while every caller ends its path with the current step; the
        // first caller that does not gets a working link drawn as though it were
        // not one. A control's appearance has to follow whether it acts.
        const isCurrent = item.onTap == null;

        return (
          <React.Fragment key={item.key ?? `${item.label}-${index}`}>
            {index > 0 ? (
              // Punctuation. A reader announcing "chevron right" nine times on a
              // deep path is noise the user has to sit through.
              <MxIcon
                name="chevron-right"
                size="sm"
                className="mx-breadcrumb__separator"
              />
            ) : null}
            {isCurrent ? (
              <span
                className="mx-breadcrumb__step mx-breadcrumb__step--current"
                aria-current="page"
              >
                {item.label}
              </span>
            ) : (
              <button
                type="button"
                className="mx-breadcrumb__step mx-focus-ring"
                onClick={item.onTap}
              >
                {item.label}
              </button>
            )}
          </React.Fragment>
        );
      })}
    </nav>
  );
}

export default MxBreadcrumb;
