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
 * A step with no onTap renders as quiet text rather than a control that does
 * nothing — derived from the callback, never from position in the list.
 */
export function MxBreadcrumb({ items, semanticLabel, rootIcon, collapseAfter = 4 }) {
  const [expanded, setExpanded] = React.useState(false);
  const strip = React.useRef(null);

  // A path the user just walked into should show its deep end, not its root.
  React.useEffect(() => {
    if (strip.current) strip.current.scrollLeft = strip.current.scrollWidth;
  }, [items.length, expanded]);

  if (!items || items.length === 0) return null;

  const folded = !expanded && items.length > collapseAfter;
  const shown = folded ? [items[0], { fold: true }, ...items.slice(-2)] : items;

  return (
    <div className="mx-crumbs" role="navigation" aria-label={semanticLabel} ref={strip}>
      {shown.map((item, i) => (
        <React.Fragment key={item.fold ? 'fold' : item.label + i}>
          {i > 0 ? <MxIcon name="chevron_right" filled size="var(--icon-sm)" className="mx-crumbs__sep" /> : null}
          {item.fold ? (
            <button type="button" className="mx-crumbs__step mx-crumbs__step--fold" onClick={() => setExpanded(true)} aria-label={`Show ${items.length - 3} hidden steps`}>…</button>
          ) : item.onTap ? (
            <button type="button" className="mx-crumbs__step mx-crumbs__step--link" onClick={item.onTap}>
              {i === 0 && rootIcon ? <MxIcon name={rootIcon} filled size="var(--icon-sm)" /> : null}
              {item.label}
            </button>
          ) : (
            <span className="mx-crumbs__step mx-crumbs__step--current">{item.label}</span>
          )}
        </React.Fragment>
      ))}
    </div>
  );
}
