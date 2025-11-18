import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/csv_service.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge ?? TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
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
                await CsvService.backupPrograms();
              },
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('Import CSV'),
              subtitle: Text('Import a program from a CSV file'),
              onTap: () async {
                await CsvService.importProgramFromCsv();
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
