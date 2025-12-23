/**
 * Web Share Utility
 *
 * Provides native sharing on mobile devices and clipboard fallback on desktop.
 * Uses the Web Share API when available (modern mobile browsers).
 */

export interface ShareOptions {
  url: string;
  title: string;
  text?: string;
}

/**
 * Share a URL using the Web Share API or clipboard fallback
 * @param options - Share configuration
 * @returns Promise that resolves when sharing is complete
 */
export async function shareUrl(options: ShareOptions): Promise<void> {
  const { url, title, text } = options;

  // Check if Web Share API is available (mobile browsers, modern desktop browsers)
  if (navigator.share) {
    try {
      await navigator.share({
        title,
        text: text || title,
        url
      });
      return;
    } catch (error: any) {
      // User cancelled the share - this is normal, don't show error
      if (error.name === 'AbortError') {
        return;
      }
      // Fall through to clipboard fallback if share fails
      console.warn('Web Share API failed, falling back to clipboard:', error);
    }
  }

  // Fallback: Copy to clipboard
  try {
    await navigator.clipboard.writeText(url);
    // Show a temporary success message
    showCopiedToast();
  } catch (error) {
    console.error('Failed to copy to clipboard:', error);
    throw new Error('Failed to share link');
  }
}

/**
 * Show a temporary "Copied!" toast message
 */
function showCopiedToast() {
  // Create toast element
  const toast = document.createElement('div');
  toast.textContent = 'Link copied to clipboard!';
  toast.style.cssText = `
    position: fixed;
    bottom: 80px;
    left: 50%;
    transform: translateX(-50%);
    background-color: #333;
    color: white;
    padding: 12px 24px;
    border-radius: 8px;
    font-size: 14px;
    z-index: 9999;
    opacity: 0;
    transition: opacity 0.3s ease;
  `;

  document.body.appendChild(toast);

  // Fade in
  setTimeout(() => {
    toast.style.opacity = '1';
  }, 10);

  // Fade out and remove
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => {
      document.body.removeChild(toast);
    }, 300);
  }, 2000);
}
