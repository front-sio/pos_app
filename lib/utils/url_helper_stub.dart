/// Stub implementation for non-web platforms
/// On mobile/desktop, we don't have access to browser URL
class UrlHelper {
  static Uri? getBrowserUri() {
    // On non-web platforms, we can't access browser URL
    // Return null to indicate no special routing needed
    return null;
  }
  
  static void pushBrowserHistoryState(String title, String url) {
    // No-op on non-web platforms (no browser history to manipulate)
  }
}
