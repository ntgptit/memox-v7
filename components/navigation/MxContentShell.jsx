import React from 'react';

/**
 * The screen shell every screen uses.
 *
 * Exists so screen padding and the app-bar shape are decided once. Without it each
 * screen picks its own padding and the difference is visible the moment two screens
 * sit next to each other in a flow.
 */
export function MxContentShell({
  children,
  title,
  actions,
  leading,
  padding,
  isScrollable = false,
  floatingActionButton,
  navigationBar,
  className = '',
  ...rest
}) {
  return (
    <div className={`mx-shell ${className}`.trim()} {...rest}>
      {title != null ? (
        // No tint on scroll and no elevation: during a review the header must stay
        // still, because a colour shift behind the card reads as the card itself
        // changing.
        <header className="mx-shell__app-bar">
          {leading}
          <h1 className="mx-shell__title mx-type-title-large">{title}</h1>
          {actions ? <div className="mx-shell__actions">{actions}</div> : null}
        </header>
      ) : null}

      {/* `main`, and the padding resolves from the viewport rather than from a
          prop: 16 a side costs 10% of a 320-wide screen and 8% of a 393-wide one.
          The gutter is the same number and a different amount of the screen, which
          is what makes a narrow phone feel padded rather than laid out. */}
      <main
        className={[
          'mx-shell__body',
          isScrollable ? 'mx-shell__body--scrollable' : '',
        ]
          .filter(Boolean)
          .join(' ')}
        style={padding == null ? undefined : { padding }}
      >
        {children}
      </main>

      {/* Passed to the shell rather than stacked into the body by the caller: the
          shell is what keeps a floating action clear of the safe-area inset and of
          the navigation bar it sits above. It reserves no space — a scrolling body
          still has to end with enough bottom padding for its last item to clear the
          button. */}
      {floatingActionButton}

      {navigationBar}
    </div>
  );
}

export default MxContentShell;
