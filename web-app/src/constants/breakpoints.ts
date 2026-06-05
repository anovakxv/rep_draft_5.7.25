/**
 * Responsive breakpoints for the application
 *
 * BREAKPOINT STRATEGY:
 * - Mobile: < 1024px (phones and small tablets)
 * - Desktop: >= 1024px (laptops, desktops, and large tablets in landscape)
 *
 * Matches Tailwind's `lg` breakpoint used in MainScreen.vue's hidden/lg:flex
 * toggle so all pages switch to desktop layout at the same viewport width.
 * Note: iPad Pro in landscape (1024px) will receive the desktop layout.
 */

export const BREAKPOINTS = {
  /** Desktop breakpoint in pixels */
  DESKTOP: 1024,

  /** Desktop breakpoint for CSS media queries */
  DESKTOP_MEDIA_QUERY: '1024px',
} as const;

/**
 * Check if current viewport is desktop size
 * @returns true if viewport width >= desktop breakpoint
 */
export function isDesktopViewport(): boolean {
  return window.innerWidth >= BREAKPOINTS.DESKTOP;
}
