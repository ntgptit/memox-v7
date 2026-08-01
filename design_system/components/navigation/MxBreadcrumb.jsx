import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';

/**
 * Where this level sits in the tree. Scrolls horizontally and therefore cannot
 * overflow: wrapping turns a deep path into five lines of chrome.
 *
 * Past `collapseAfter` steps it folds the middle into a single "…" the user can
 * expand in place. Collapsing rather than truncating matters because the two
 * ends are the two the user actually navigates to — the root they came from and
 * the parent they are about to go back to — while the middle is the part they
 * scrolled past. The fold is reversible; a truncation is not.
 *
 * It starts at the LEFT and stays there. It used to jump to its deep end on
 * arrival; the fold made that obsolete, because above `collapseAfter` the strip
 * is already first · fold · last two — the deep end is on screen without
 * scrolling, and the jump cost the one thing a path is read for, which is seeing
 * where it begins.
 *
 * A step with no onTap renders as quiet text rather than a control that does
 * nothing — derived from the callback, never from position in the list.
 *
 * Every state is on the TEXT, never on a surface behind it. A hover that fills a
 * rounded box behind each word turns a path into a row of buttons, and the boxes
 * flick on and off as the pointer crosses the strip.
 */
export function MxBreadcrumb({ items, semanticLabel, rootIcon, collapseAfter = 4 }) {
  const [expanded, setExpanded] = React.useState(false);

  if (!items || items.length === 0) return null;

  const folded = !expanded && items.length > collapseAfter;
  const shown = folded ? [items[0], { fold: true }, ...items.slice(-2)] : items;

  return (
    <div className="mx-crumbs" role="navigation" aria-label={semanticLabel}>
      {shown.map((item, i) => (
        <React.Fragment key={item.fold ? 'fold' : item.label + i}>
          {i > 0 ? <MxIcon name="chevron_right" filled size="var(--icon-sm)" className="mx-crumbs__sep" /> : null}
          {item.fold ? (
            <button type="button" className="mx-crumbs__step mx-crumbs__step--fold" onClick={() => setExpanded(true)} aria-label={`Show ${items.length - 3} hidden steps`}>…</button>
          ) : item.onTap ? (
            <button type="button" className="mx-crumbs__step mx-crumbs__step--link" onClick={item.onTap}>
              {i === 0 && rootIcon ? <MxIcon name={rootIcon} filled size="var(--icon-sm)" /> : null}
              <span className="mx-crumbs__label">{item.label}</span>
            </button>
          ) : (
            // The glyph is drawn on BOTH branches. Rendering it only on the
            // tappable one took the home icon off the one strip where the first
            // step is also the current one — the top of the tree, where the mark
            // that makes it recognisable without reading matters most.
            <span className="mx-crumbs__step mx-crumbs__step--current">
              {i === 0 && rootIcon ? <MxIcon name={rootIcon} filled size="var(--icon-sm)" /> : null}
              {item.label}
            </span>
          )}
        </React.Fragment>
      ))}
    </div>
  );
}
