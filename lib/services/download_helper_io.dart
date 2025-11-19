// IO stub for non-web platforms. Uses platform's file system (no-op triggerDownload)
import 'dart:io';

Future<void> triggerDownload(String fileName, String content) async {
  // Not used on IO platforms; callers should save directly via File APIs.
  // Provide a fallback that writes to temp directory for convenience.
  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
}

