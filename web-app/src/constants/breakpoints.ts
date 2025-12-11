/**
 * Responsive breakpoints for the application
 *
 * BREAKPOINT STRATEGY:
 * - Mobile: < 1024px (phones and tablets, including iPads)
 * - Desktop: >= 1024px (laptops and desktop computers)
 *
 * This ensures tablets get the mobile-optimized layout while
 * preserving the desktop experience for larger screens.
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
