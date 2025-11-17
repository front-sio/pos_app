/// Web-specific implementation using dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class UrlHelper {
  static Uri? getBrowserUri() {
    try {
      // On web, get the current browser URL
      return Uri.parse(html.window.location.href);
    } catch (e) {
      return null;
    }
  }
  
  static void pushBrowserHistoryState(String title, String url) {
    try {
      // Update browser history on web
      html.window.history.pushState(null, title, url);
    } catch (e) {
      // Ignore errors
    }
  }
}
