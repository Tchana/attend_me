// Conditional export: uses web implementation when compiled to web, otherwise uses IO stub.
export 'download_helper_io.dart' if (dart.library.html) 'download_helper_web.dart';

// The selected implementation exposes triggerDownload(String fileName, String content)
// No further code needed here; the imported file provides the function.
