/**
 * Responsive breakpoints for the application
 *
 * BREAKPOINT STRATEGY:
 * - Mobile: < 1280px (phones and tablets, including all iPads)
 * - Desktop: >= 1280px (laptops and desktop computers)
 *
 * This ensures all tablets (including iPad Pro) get the mobile-optimized
 * layout while preserving the desktop experience for larger screens.
 */

export const BREAKPOINTS = {
  /** Desktop breakpoint in pixels */
  DESKTOP: 1280,

  /** Desktop breakpoint for CSS media queries */
  DESKTOP_MEDIA_QUERY: '1280px',
} as const;

/**
 * Check if current viewport is desktop size
 * @returns true if viewport width >= desktop breakpoint
 */
export function isDesktopViewport(): boolean {
  return window.innerWidth >= BREAKPOINTS.DESKTOP;
}
