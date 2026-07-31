import React from 'react';

import MxIcon from '../core/MxIcon.jsx';
import MxListTile from '../core/MxListTile.jsx';

/**
 * The mobile action menu.
 *
 * It decides nothing. Which actions exist, whether "Create card" belongs beside
 * "Create deck", whether either is available for this content — all of that is the
 * caller's, and arrives as a list. A sheet that knew about content types would have
 * to know about schedulers next, and then about permissions.
 *
 * Dismissal belongs to the caller that opened it, for the same reason
 * `MxConfirmDialog` does not close itself: the sheet does not know whether the
 * action it just fired succeeded.
 */
export function MxActionSheet({ actions, title, onDismiss, className = '', ...rest }) {
  const titleId = React.useId();

  return (
    <div className="mx-scrim mx-sheet-scrim" onClick={onDismiss}>
      <div
        className={`mx-sheet ${className}`.trim()}
        role="menu"
        aria-labelledby={title ? titleId : undefined}
        onClick={(event) => event.stopPropagation()}
        onKeyDown={(event) => {
          if (event.key === 'Escape') onDismiss?.();
        }}
        {...rest}
      >
        <div className="mx-sheet__handle" aria-hidden="true" />
        {title ? (
          <div id={titleId} className="mx-sheet__title mx-type-title-small">
            {title}
          </div>
        ) : null}
        {actions.map((action, index) => {
          const isDestructive = action.variant === 'destructive';
          const isEnabled = action.isEnabled !== false;

          return (
            <MxListTile
              key={action.key ?? `${action.label}-${index}`}
              role="menuitem"
              className={[
                'mx-sheet__action',
                isDestructive ? 'mx-sheet__action--destructive' : '',
              ]
                .filter(Boolean)
                .join(' ')}
              title={action.label}
              // Not the label's colour on a normal row: a glyph carrying the same
              // weight as the words next to it leaves the eye two things to land
              // on. Destructive keeps the full colour, because there the glyph is
              // part of the warning and quieting it would leave red text beside a
              // neutral bin — `mx-sheet__action--destructive` does that in CSS.
              leading={action.icon ? <MxIcon name={action.icon} size="md" /> : undefined}
              onTap={action.onPressed}
              // The row stays visible when unavailable, on purpose: hiding it makes
              // the menu change shape between visits, and the user cannot learn
              // where anything is.
              isEnabled={isEnabled}
            />
          );
        })}
      </div>
    </div>
  );
}

export default MxActionSheet;
