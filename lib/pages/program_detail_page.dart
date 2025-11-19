import 'package:attend_me/services/csv_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';
import 'add_attendant_page.dart';
import 'add_session_page.dart';
import 'take_attendance_page.dart';
import 'analytics_page.dart';

class ProgramDetailPage extends StatefulWidget {
  final String programId;
  final ProgramController ctrl = Get.find();

  ProgramDetailPage({required this.programId});

  @override
  _ProgramDetailPageState createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _attendantSearchController =
      TextEditingController();
  final TextEditingController _sessionSearchController =
      TextEditingController();
  String _attendantQuery = '';
  String _sessionQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _attendantSearchController.addListener(() {
      setState(() {
        _attendantQuery =
            _attendantSearchController.text.trim().toLowerCase();
      });
    });
    _sessionSearchController.addListener(() {
      setState(() {
        _sessionQuery = _sessionSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _attendantSearchController.dispose();
    _sessionSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Format date to show only YYYY-MM-DD
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Show confirmation dialog before deleting a attendant
  void _confirmDeleteAttendant(String attendantId, String attendantName) {
    Get.defaultDialog(
      title: "Delete Attendant",
      middleText:
          "Are you sure you want to delete '$attendantName'? This action cannot be undone and all attendance records for this attendant will be lost.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Color(0xFFF9F9F9),
      buttonColor: Colors.red,
      onConfirm: () {
        widget.ctrl.removeAttendant(widget.programId, attendantId);
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
      final program =
          widget.ctrl.programs.firstWhere((t) => t.id == widget.programId);
      final attendants = program.attendants
          .where((tr) =>
              _attendantQuery.isEmpty ||
              tr.name.toLowerCase().contains(_attendantQuery))
          .toList();
      final sessions = program.sessions
          .where((session) =>
              _sessionQuery.isEmpty ||
              session.title.toLowerCase().contains(_sessionQuery))
          .toList();
      return Scaffold(
        backgroundColor: Color(0xFFEEEEEE),
        appBar: AppBar(
          title: Text(program.title),
          actions: [
            IconButton(
              icon: Icon(Icons.upload_file),
              tooltip: 'Export CSV',
              onPressed: () => CsvService.exportProgramToCsv(widget.programId),
            ),
            IconButton(
              icon: Icon(Icons.bar_chart),
              onPressed: () =>
                  Get.to(() => AnalyticsPage(programId: widget.programId)),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Attendants'),
              Tab(text: 'Sessions'),
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Attendants tab
                    Column(
                      children: [
                        ListTile(
                          title: Text('Attendants'),
                          trailing: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              await Get.to(() => AddAttendantPage(
                                  programId: widget.programId));
                              // After returning, ensure we're on the attendant tab
                              Future.delayed(Duration(milliseconds: 100), () {
                                _tabController.animateTo(0);
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _attendantSearchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search attendants by name',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: attendants.length,
                            itemBuilder: (_, i) {
                              final tr = attendants[i];
                              return ListTile(
                                title: Text(tr.name),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      _confirmDeleteAttendant(tr.id, tr.name),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // Sessions tab
                    Column(
                      children: [
                        ListTile(
                          title: Text('Sessions'),
                          trailing: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () async {
                              await Get.to(() =>
                                  AddSessionPage(programId: widget.programId));
                              // After returning, ensure we're on the session tab
                              Future.delayed(Duration(milliseconds: 100), () {
                                _tabController.animateTo(1);
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _sessionSearchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search sessions by title',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: sessions.length,
                            itemBuilder: (_, i) {
                              final l = sessions[i];
                              return ListTile(
                                title: Text(l.title),
                                subtitle: Text(
                                    '${_formatDate(l.date.toLocal())} • ${l.isNewChapter ? "New chapter" : "Continuation"}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.checklist),
                                  onPressed: () => Get.to(() =>
                                      TakeAttendancePage(
                                          programId: widget.programId,
                                          sessionId: l.id)),
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
