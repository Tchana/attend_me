import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';
import '../models/attendance.dart';

class TakeAttendancePage extends StatefulWidget {
  final String trainingId;
  final String lessonId;
  final TrainingController ctrl = Get.find<TrainingController>();

  TakeAttendancePage({required this.trainingId, required this.lessonId});

  @override
  _TakeAttendancePageState createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  // Map to keep track of attendance status for immediate UI updates
  Map<String, PresenceStatus> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeAttendanceStatus();
  }

  // Initialize attendance status from existing data
  void _initializeAttendanceStatus() {
    final training =
        widget.ctrl.trainings.firstWhere((t) => t.id == widget.trainingId);
    final lesson = training.lessons.firstWhere((l) => l.id == widget.lessonId);

    for (var tr in training.trainees) {
      try {
        final att = lesson.attendance.firstWhere((a) => a.traineeId == tr.id);
        _attendanceStatus[tr.id] = att.status;
      } catch (e) {
        // If attendance record doesn't exist, use default
        _attendanceStatus[tr.id] = PresenceStatus.Absent;
      }
    }
  }

  // Helper method to find attendance or return default
  Attendance _findAttendanceOrDefault(
      List<Attendance> attendanceList, String traineeId) {
    try {
      return attendanceList.firstWhere((a) => a.traineeId == traineeId);
    } catch (e) {
      // If attendance record doesn't exist, create a default one
      return Attendance(traineeId: traineeId, status: PresenceStatus.Absent);
    }
  }

  // Update attendance status and UI immediately
  void _updateAttendance(String traineeId, PresenceStatus status) {
    setState(() {
      _attendanceStatus[traineeId] = status;
    });

    // Call the controller method to persist the change
    widget.ctrl.updateAttendance(
        widget.trainingId, widget.lessonId, traineeId, status);
  }

  @override
  Widget build(BuildContext context) {
    final training =
        widget.ctrl.trainings.firstWhere((t) => t.id == widget.trainingId);
    final lesson = training.lessons.firstWhere((l) => l.id == widget.lessonId);

    return Scaffold(
      appBar: AppBar(title: Text('Attendance - ${lesson.title}')),
      body: ListView.builder(
        itemCount: training.trainees.length,
        itemBuilder: (_, i) {
          final tr = training.trainees[i];
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
