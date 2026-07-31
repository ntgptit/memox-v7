import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';

/**
 * The search bar that sits under an app bar. Not MxTextField: that one is a
 * form control with a floating label and a 1.5px outline, and a search bar with
 * a label above it reads as something you have to fill in before continuing.
 *
 * It searches nothing itself — it reports what was typed. Whether that means a
 * flat scan of one level or a walk of the whole subtree is the screen's
 * decision, and the two want different result rows.
 */
export function MxSearchField({ value, onChange, placeholder, resultCount, autoFocus = false }) {
  return (
    <div className="mx-search">
      <MxIcon name="search" filled size="var(--icon-sm)" className="mx-search__icon" />
      <input
        type="search"
        className="mx-search__input"
        value={value}
        placeholder={placeholder}
        autoFocus={autoFocus}
        onChange={(e) => onChange(e.target.value)}
        aria-label={placeholder}
      />
      {value ? (
        <React.Fragment>
          {resultCount !== undefined ? <span className="mx-search__count">{resultCount}</span> : null}
          <button type="button" className="mx-search__clear" onClick={() => onChange('')} aria-label="Clear search">
            <MxIcon name="close" filled size="var(--icon-sm)" />
          </button>
        </React.Fragment>
      ) : null}
    </div>
  );
}
