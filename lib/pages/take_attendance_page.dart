import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';
import '../models/attendance.dart';

class TakeAttendancePage extends StatefulWidget {
  final String programId;
  final String sessionId;
  final ProgramController ctrl = Get.find<ProgramController>();

  TakeAttendancePage({required this.programId, required this.sessionId});

  @override
  _TakeAttendancePageState createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  // Map to keep track of attendance status for immediate UI updates
  Map<String, PresenceStatus> _attendanceStatus = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAttendanceStatus();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Initialize attendance status from existing data
  void _initializeAttendanceStatus() {
    final program =
        widget.ctrl.programs.firstWhere((t) => t.id == widget.programId);
    final session =
        program.sessions.firstWhere((l) => l.id == widget.sessionId);

    for (var tr in program.attendants) {
      try {
        final att =
            session.attendance.firstWhere((a) => a.attendantId == tr.id);
        _attendanceStatus[tr.id] = att.status;
      } catch (e) {
        // If attendance record doesn't exist, use default
        _attendanceStatus[tr.id] = PresenceStatus.Absent;
      }
    }
  }

  // Update attendance status and UI immediately
  void _updateAttendance(String attendantId, PresenceStatus status) {
    setState(() {
      _attendanceStatus[attendantId] = status;
    });

    // Call the controller method to persist the change
    widget.ctrl.updateAttendance(
        widget.programId, widget.sessionId, attendantId, status);
  }

  @override
  Widget build(BuildContext context) {
    final program =
        widget.ctrl.programs.firstWhere((t) => t.id == widget.programId);
    final session =
        program.sessions.firstWhere((l) => l.id == widget.sessionId);
    final attendants = program.attendants
        .where((tr) =>
            _searchQuery.isEmpty ||
            tr.name.toLowerCase().contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFF),
        title: Text('Attendance - ${session.title}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search attendants by name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: attendants.length,
              itemBuilder: (_, i) {
                final tr = attendants[i];
                // Get current status from our local map
                final currentStatus =
                    _attendanceStatus[tr.id] ?? PresenceStatus.Absent;

                return ListTile(
                  title: Text(tr.name),
                  subtitle: Text(_getStatusText(currentStatus)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        icon: Icon(Icons.check_circle,
                            color: currentStatus == PresenceStatus.Present
                                ? Colors.green
                                : Colors.grey),
                        onPressed: () =>
                            _updateAttendance(tr.id, PresenceStatus.Present)),
                    IconButton(
                        icon: Icon(Icons.close,
                            color: currentStatus == PresenceStatus.Absent
                                ? Colors.red
                                : Colors.grey),
                        onPressed: () =>
                            _updateAttendance(tr.id, PresenceStatus.Absent)),
                    IconButton(
                        icon: Icon(Icons.autorenew,
                            color: currentStatus == PresenceStatus.CatchUp
                                ? Colors.orange
                                : Colors.grey),
                        onPressed: () =>
                            _updateAttendance(tr.id, PresenceStatus.CatchUp)),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get status text
  String _getStatusText(PresenceStatus status) {
    switch (status) {
      case PresenceStatus.Present:
        return 'Present';
      case PresenceStatus.Absent:
        return 'Absent';
      case PresenceStatus.CatchUp:
        return 'Catch Up';
      default:
        return 'Absent';
    }
  }
}
