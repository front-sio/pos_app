import 'dart:html' as html;

bool isOnline() {
  return html.window.navigator.onLine ?? true;
}

void addOnlineListener(Function() callback) {
  html.window.addEventListener('online', (event) {
    callback();
  });
}

void addOfflineListener(Function() callback) {
  html.window.addEventListener('offline', (event) {
    callback();
  });
}
