import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';
import '../services/csv_service.dart';
import 'program_detail_page.dart';
import 'create_program_page.dart';

class HomePage extends StatelessWidget {
  final ProgramController ctrl = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Programs'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.backup),
            tooltip: 'Backup Data',
            onPressed: () async {
              await CsvService.backupPrograms();
            },
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            tooltip: 'Import CSV',
            onPressed: () async {
              await CsvService.importProgramFromCsv();
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Get.snackbar(
                'Help',
                'Tap on a program to view details. Use the + button to create a new program.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final items = ctrl.programs;
        if (items.isEmpty) {
          return _buildEmptyState();
        }
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Get.to(() => ProgramDetailPage(programId: t.id));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDelete(context, t.id, t.title);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          t.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.school,
                              '${t.sessions.length} sessions',
                              Colors.blue,
                            ),
                            SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.people,
                              '${t.attendants.length} attendants',
                              Colors.green,
                            ),
                            if (t.googleSheetUrl.isNotEmpty) ...[
                              SizedBox(width: 12),
                              _buildInfoChip(
                                Icons.link,
                                'Linked',
                                Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add),
        onPressed: () {
          Get.to(() => CreateProgramPage());
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No programs yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Create your first program to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Get.to(() => CreateProgramPage());
            },
            icon: Icon(Icons.add),
            label: Text('Create Program'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String programId, String title) {
    Get.defaultDialog(
      title: 'Delete Program',
      middleText: 'Are you sure you want to delete "$title"?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        ctrl.deleteProgram(programId);
        Get.back();
      },
    );
  }
}