import React from 'react';

/**
 * The app's icon set.
 *
 * A closed registry, not a `src` or a `children` prop. The moment a caller can
 * pass arbitrary artwork the set stops being a set: two screens draw two
 * different bins, and no reviewer can tell an intentional variant from a paste.
 * An unknown name renders nothing and warns, so a typo fails where it is written
 * rather than shipping as a blank square.
 *
 * Drawn on a 24 grid at a 1.5 stroke, which is the weight that survives being
 * scaled to `sm` without the counters filling in and to `lg` without turning into
 * a hairline. Every glyph inherits `currentColor` — an icon inside a control is
 * the control's colour, and that is what stops a glyph and its label drifting
 * apart when someone restyles one of them.
 *
 * Size is one of three steps and never a number: `sm` inline with body text, `md`
 * for actions and list affordances, `lg` for the illustrative icon in an empty or
 * error state. A fourth would be a guess, and a free number is how a design system
 * acquires eleven icon sizes.
 */

const ICONS = {
  check: <path d="m4.5 12.4 5 5 10-10.8" />,
  'check-circle': (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="m8 12.3 2.7 2.7 5.6-5.7" />
    </>
  ),
  'alert-circle': (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7.4v5.4" />
      <path d="M12 16.3v.4" />
    </>
  ),
  'alert-triangle': (
    <>
      <path d="M12 3.8 2.8 20h18.4z" />
      <path d="M12 9.6v4.2" />
      <path d="M12 16.9v.4" />
    </>
  ),
  info: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11.2v5.4" />
      <path d="M12 7.4v.4" />
    </>
  ),
  'chevron-right': <path d="m9.5 5.5 7 6.5-7 6.5" />,
  'chevron-left': <path d="m14.5 5.5-7 6.5 7 6.5" />,
  'chevron-down': <path d="m5.5 9.5 6.5 7 6.5-7" />,
  'arrow-left': (
    <>
      <path d="M20 12H4.4" />
      <path d="m10.4 6-6 6 6 6" />
    </>
  ),
  'arrow-right': (
    <>
      <path d="M4 12h15.6" />
      <path d="m13.6 6 6 6-6 6" />
    </>
  ),
  search: (
    <>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m15.8 15.8 4.4 4.4" />
    </>
  ),
  close: (
    <>
      <path d="m6.2 6.2 11.6 11.6" />
      <path d="m17.8 6.2-11.6 11.6" />
    </>
  ),
  plus: (
    <>
      <path d="M12 5v14" />
      <path d="M5 12h14" />
    </>
  ),
  minus: <path d="M5 12h14" />,
  menu: (
    <>
      <path d="M4 7h16" />
      <path d="M4 12h16" />
      <path d="M4 17h16" />
    </>
  ),
  'more-vertical': (
    <>
      <circle cx="12" cy="5.2" r="1.5" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.5" fill="currentColor" stroke="none" />
      <circle cx="12" cy="18.8" r="1.5" fill="currentColor" stroke="none" />
    </>
  ),
  edit: (
    <>
      <path d="M4.5 19.5h4L18.4 9.6l-4-4L4.5 15.5z" />
      <path d="m14.4 5.6 4 4" />
    </>
  ),
  trash: (
    <>
      <path d="M4.5 7h15" />
      <path d="M9.5 7V4.8h5V7" />
      <path d="M6.6 7v12.2h10.8V7" />
      <path d="M10.4 10.6v5.6" />
      <path d="M13.6 10.6v5.6" />
    </>
  ),
  refresh: (
    <>
      <path d="M19.5 12a7.5 7.5 0 1 1-2.4-5.5" />
      <path d="M19.6 4.6v4.3h-4.3" />
    </>
  ),
  inbox: (
    <>
      <path d="M3.5 13.4 6.2 5h11.6l2.7 8.4v5.6H3.5z" />
      <path d="M3.5 13.4h4.3l1.2 2.5h6l1.2-2.5h4.3" />
    </>
  ),
  folder: <path d="M3.6 5.5h5.6l2 2.6h9.2v10.4H3.6z" />,
  layers: (
    <>
      <path d="m12 4 8.4 4.4L12 12.8 3.6 8.4z" />
      <path d="m4.6 12.4 7.4 3.9 7.4-3.9" />
    </>
  ),
  clock: (
    <>
      <circle cx="12" cy="12" r="8.6" />
      <path d="M12 6.8v5.5l3.4 2" />
    </>
  ),
  calendar: (
    <>
      <rect x="3.6" y="5.6" width="16.8" height="14.8" rx="2.6" />
      <path d="M3.6 10.2h16.8" />
      <path d="M8.2 3.6v4" />
      <path d="M15.8 3.6v4" />
    </>
  ),
  star: <path d="m12 4 2.5 5.3 5.8.8-4.2 4 1 5.9L12 17.2 6.9 20l1-5.9-4.2-4 5.8-.8z" />,
  filter: <path d="M4 5.6h16l-6.3 7.1v5.9l-3.4 1.8v-7.7z" />,
  sort: (
    <>
      <path d="M6.4 4.8v14.4" />
      <path d="m3.4 15.6 3 3.6 3-3.6" />
      <path d="M12.8 7h7.8" />
      <path d="M12.8 12h5.8" />
      <path d="M12.8 17h3.8" />
    </>
  ),
  // Sliders rather than a gear. A stroked gear needs eight detached teeth around a
  // small circle, and at 24 that reads as a sun — which is what the first version
  // of this glyph was mistaken for.
  settings: (
    <>
      <path d="M4 8.4h9.6" />
      <path d="M18.4 8.4H20" />
      <circle cx="16" cy="8.4" r="2.4" />
      <path d="M4 15.6h4.4" />
      <path d="M13.2 15.6H20" />
      <circle cx="10.8" cy="15.6" r="2.4" />
    </>
  ),
};

/** The names this set draws. Exported so a test can assert a caller's name exists. */
export const MX_ICON_NAMES = Object.keys(ICONS);

export function MxIcon({ name, size = 'md', label, className = '', ...rest }) {
  const glyph = ICONS[name];

  if (glyph === undefined) {
    // Loud in development, blank in production — the same trade `MxIcon`'s Dart
    // counterpart gets for free from a typed `IconData`.
    if (typeof console !== 'undefined') {
      console.warn(`MxIcon: no icon named "${name}". Known names: ${MX_ICON_NAMES.join(', ')}`);
    }

    return null;
  }

  // Decorative unless told otherwise. An icon beside its own label is read twice
  // when it carries a name of its own, and "chevron right" nine times down a
  // breadcrumb is noise the user has to sit through. `label` is for the case where
  // the glyph IS the content — an empty state's illustration, an icon-only status.
  const semantics = label
    ? { role: 'img', 'aria-label': label }
    : { 'aria-hidden': 'true', focusable: 'false' };

  return (
    <svg
      className={`mx-icon mx-icon--${size} ${className}`.trim()}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...semantics}
      {...rest}
    >
      {glyph}
    </svg>
  );
}

export default MxIcon;
