import React from 'react';

/* MxCard — surface container. Base class: card */
export function MxCard({ variant, interactive = false, padding, node, className = '', children, onClick, style }) {
  const cls = ['card'];
  if (variant) cls.push('card--' + variant);
  if (interactive) cls.push('card--interactive');
  if (padding) cls.push('card--pad-' + padding);
  if (className) cls.push(className);
  return (
    <div className={cls.join(' ')} data-mx-node={node} onClick={onClick} style={style}>
      {children}
    </div>
  );
}
