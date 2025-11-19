import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/csv_service.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.backup),
              title: Text('Backup Data'),
              subtitle: Text('Export all programs to a backup file'),
              onTap: () async {
                // On web we cannot pick a directory reliably
                if (kIsWeb) {
                  final proceed = await Get.defaultDialog<bool>(
                    title: 'Directory selection not available',
                    middleText: 'Directory selection is not available on web. Copy backup JSON to clipboard instead?',
                    textConfirm: 'Yes',
                    textCancel: 'Cancel',
                  );
                  if (proceed == true) {
                    await CsvService.backupPrograms();
                  }
                  return;
                }

                try {
                  // Ask the user to pick a directory
                  final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose backup folder');
                  if (selectedDirectory == null || selectedDirectory.isEmpty) {
                    // user cancelled
                    Get.snackbar('Cancelled', 'No folder selected for backup');
                    return;
                  }

                  // Attempt to write backup only to the selected directory
                  final savedPath = await CsvService.backupProgramsToDirectory(selectedDirectory);
                  if (savedPath != null) {
                    Get.snackbar('Backup Successful', 'Backup saved to:\n$savedPath', duration: Duration(seconds: 8));
                  } else {
                    Get.snackbar('Backup Failed', 'Could not save backup to the selected location.', duration: Duration(seconds: 8), backgroundColor: Colors.redAccent, colorText: Color(0xFFF9F9F9));
                  }
                } on UnimplementedError catch (e) {
                  // Some platforms may throw unimplemented for directory picking
                  Get.snackbar('Not supported', 'Directory picking not supported on this platform: ${e.toString()}', backgroundColor: Colors.orangeAccent);
                  final proceed = await Get.defaultDialog<bool>(
                    title: 'Fallback',
                    middleText: 'Directory picking not available. Copy backup JSON to clipboard instead?',
                    textConfirm: 'Yes',
                    textCancel: 'Cancel',
                  );
                  if (proceed == true) {
                    await CsvService.backupPrograms();
                  }
                } catch (e) {
                  // For other errors, fall back to the generic backup routine which will try other strategies
                  print('Error during backup: $e');
                  final proceed = await Get.defaultDialog<bool>(
                    title: 'Backup error',
                    middleText: 'Could not open folder picker. Fallback to automatic backup (copy to clipboard) ?\n\nError: $e',
                    textConfirm: 'Yes',
                    textCancel: 'Cancel',
                  );
                  if (proceed == true) {
                    await CsvService.backupPrograms();
                  }
                }
              },
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('Import Data'),
              subtitle: Text('Import programs from a backup JSON file'),
              onTap: () async {
                try {
                  await CsvService.importBackupJson();
                } catch (e) {
                  Get.snackbar('Import error', e.toString(), backgroundColor: Colors.redAccent, colorText: Color(0xFFF9F9F9));
                }
              },
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Help'),
              subtitle: Text('Tips and guidance about using the app'),
              onTap: () {
                Get.defaultDialog(
                  title: 'Help',
                  middleText: 'Tap on a program to view details. Use the + button to create a new program. Use Backup to export data and Import to add a program from CSV.',
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Use AuthController if available
                if (Get.isRegistered<AuthController>()) {
                  final auth = Get.find<AuthController>();
                  auth.logout();
                }
                Get.offAllNamed('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}
