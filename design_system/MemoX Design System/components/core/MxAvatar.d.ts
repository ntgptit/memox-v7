export interface MxAvatarProps {
  /** Display name — used for initials fallback. */
  name?: string;
  /** Image URL. */
  src?: string;
  size?: 'sm' | 'lg';
  variant?: 'accent';
  /** Primary ring around the avatar. */
  ring?: boolean;
  node?: string;
}

/** Circular avatar with image or initials fallback. Base class `avatar`. */
export function MxAvatar(props: MxAvatarProps): JSX.Element;
