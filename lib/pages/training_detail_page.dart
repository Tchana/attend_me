import 'package:attend_me/services/csv_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';
import 'add_trainee_page.dart';
import 'add_lesson_page.dart';
import 'take_attendance_page.dart';
import 'analytics_page.dart';

class TrainingDetailPage extends StatefulWidget {
  final String trainingId;
  final TrainingController ctrl = Get.find();

  TrainingDetailPage({required this.trainingId});

  @override
  _TrainingDetailPageState createState() => _TrainingDetailPageState();
}

class _TrainingDetailPageState extends State<TrainingDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Format date to show only YYYY-MM-DD
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Show confirmation dialog before deleting a trainee
  void _confirmDeleteTrainee(String traineeId, String traineeName) {
    Get.defaultDialog(
      title: "Delete Trainee",
      middleText:
          "Are you sure you want to delete '$traineeName'? This action cannot be undone and all attendance records for this trainee will be lost.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        widget.ctrl.removeTrainee(widget.trainingId, traineeId);
        Get.back(); // Close the dialog
      },
      onCancel: () {
        Get.back(); // Close the dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final training =
          widget.ctrl.trainings.firstWhere((t) => t.id == widget.trainingId);
      return Scaffold(
        appBar: AppBar(
          title: Text(training.title),
          actions: [
            IconButton(
              icon: Icon(Icons.bar_chart),
              onPressed: () =>
                  Get.to(() => AnalyticsPage(trainingId: widget.trainingId)),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Trainees'),
              Tab(text: 'Lessons'),
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.download),
                label: Text('Export CSV'),
                onPressed: () =>
                    CsvService.exportTrainingToCsv(widget.trainingId),
              ),
              SizedBox(height: 8),
              Text('Description: ${training.description}'),
              SizedBox(height: 8),
              Text(
                  'Google Sheet: ${training.googleSheetUrl.isEmpty ? "Not set" : training.googleSheetUrl}'),
              Divider(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Trainees tab
                    Column(
                      children: [
                        ListTile(
                          title: Text('Trainees'),
                          trailing: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              await Get.to(() => AddTraineePage(
                                  trainingId: widget.trainingId));
                              // After returning, ensure we're on the trainee tab
                              Future.delayed(Duration(milliseconds: 100), () {
                                _tabController.animateTo(0);
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: training.trainees.length,
                            itemBuilder: (_, i) {
                              final tr = training.trainees[i];
                              return ListTile(
                                title: Text(tr.name),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      _confirmDeleteTrainee(tr.id, tr.name),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // Lessons tab
                    Column(
                      children: [
                        ListTile(
                          title: Text('Lessons'),
                          trailing: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              await Get.to(() =>
                                  AddLessonPage(trainingId: widget.trainingId));
                              // After returning, ensure we're on the lesson tab
                              Future.delayed(Duration(milliseconds: 100), () {
                                _tabController.animateTo(1);
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: training.lessons.length,
                            itemBuilder: (_, i) {
                              final l = training.lessons[i];
                              return ListTile(
                                title: Text(l.title),
                                subtitle: Text(
                                    '${_formatDate(l.date.toLocal())} • ${l.isNewChapter ? "New chapter" : "Continuation"}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.checklist),
                                  onPressed: () => Get.to(() =>
                                      TakeAttendancePage(
                                          trainingId: widget.trainingId,
                                          lessonId: l.id)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
