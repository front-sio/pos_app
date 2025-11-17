/// Platform-agnostic URL helper
/// This file exports the correct implementation based on the platform
export 'url_helper_stub.dart'
    if (dart.library.html) 'url_helper_web.dart';
