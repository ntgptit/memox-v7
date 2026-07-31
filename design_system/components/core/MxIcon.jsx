import React from 'react';

/**
 * Material Icons glyph — the app's only icon source.
 *
 * memox draws every glyph from Flutter's bundled Material Icons set
 * (`Icons.folder_outlined`, `Icons.more_vert`, …). On the web that same set is
 * the `Material Icons` / `Material Icons Outlined` ligature fonts, so a name
 * here is the Dart constant with its `_outlined` suffix expressed as
 * `filled={false}`.
 */
export function MxIcon({ name, filled = false, size, color, className = '', style, ...rest }) {
  const family = filled ? 'material-icons' : 'material-icons-outlined';
  return (
    <span
      className={`${family} mx-icon ${className}`}
      aria-hidden="true"
      style={{ fontSize: size, color, ...style }}
      {...rest}
    >
      {name}
    </span>
  );
}
