import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/training.dart';
import '../models/trainee.dart';
import '../models/lesson.dart';
import '../models/attendance.dart';
import '../services/sheets_service.dart';

class TrainingController extends GetxController {
  final Box<Training> _box = Hive.box<Training>('trainings');
  final trainings = <Training>[].obs;

  final uuid = Uuid();

  @override
  void onInit() {
    super.onInit();
    _loadTrainings();
  }

  void _loadTrainings() {
    trainings.assignAll(_box.values.toList());
  }

  Future<void> createTraining(String title,
      {String desc = '', String sheetUrl = ''}) async {
    final t = Training(
        id: uuid.v4(),
        title: title,
        description: desc,
        googleSheetUrl: sheetUrl);
    await _box.put(t.id, t);
    _loadTrainings();
  }

  Future<void> deleteTraining(String id) async {
    await _box.delete(id);
    _loadTrainings();
  }

  Future<void> addTrainee(String trainingId, String name) async {
    final t = _box.get(trainingId);
    if (t == null) return;
    final newTrainee = Trainee(id: uuid.v4(), name: name);
    t.trainees.add(newTrainee);

    // Create attendance records for all existing lessons
    for (var lesson in t.lessons) {
      lesson.attendance.add(
          Attendance(traineeId: newTrainee.id, status: PresenceStatus.Absent));
    }

    await t.save();
    _loadTrainings();
  }

  Future<void> removeTrainee(String trainingId, String traineeId) async {
    final t = _box.get(trainingId);
    if (t == null) return;
    t.trainees.removeWhere((tr) => tr.id == traineeId);
    // also remove attendance entries
    for (var lesson in t.lessons) {
      lesson.attendance.removeWhere((a) => a.traineeId == traineeId);
    }
    await t.save();
    _loadTrainings();
  }

  Future<void> addLesson(
      String trainingId, String title, DateTime date, bool isNewChapter,
      {bool recurringWeekly = false, int weeks = 0}) async {
    final t = _box.get(trainingId);
    if (t == null) return;
    final lesson = Lesson(
        id: uuid.v4(), title: title, date: date, isNewChapter: isNewChapter);
    // create initial empty attendance for all trainees (default Absent)
    for (var tr in t.trainees) {
      lesson.attendance
          .add(Attendance(traineeId: tr.id, status: PresenceStatus.Absent));
    }
    t.lessons.add(lesson);
    // optionally create recurring weekly lessons
    if (recurringWeekly && weeks > 1) {
      DateTime nextDate = date;
      for (int i = 1; i < weeks; i++) {
        nextDate = nextDate.add(Duration(days: 7));
        final l2 = Lesson(
            id: uuid.v4(),
            title: title + ' (Week ${i + 1})',
            date: nextDate,
            isNewChapter: isNewChapter);
        for (var tr in t.trainees) {
          l2.attendance
              .add(Attendance(traineeId: tr.id, status: PresenceStatus.Absent));
        }
        t.lessons.add(l2);
      }
    }

    await t.save();
    _loadTrainings();

    // If Google Sheet is configured, try to sync
    if (t.googleSheetUrl.isNotEmpty) {
      SheetsService.syncTrainingToSheet(t); // fire-and-forget
    }
  }

  Future<void> updateAttendance(String trainingId, String lessonId,
      String traineeId, PresenceStatus status) async {
    final t = _box.get(trainingId);
    if (t == null) return;
    final l = t.lessons.firstWhere((x) => x.id == lessonId);

    // Find existing attendance record or create new one
    Attendance? att;
    try {
      att = l.attendance.firstWhere((a) => a.traineeId == traineeId);
    } catch (e) {
      // If attendance record doesn't exist, create a new one
      att = Attendance(traineeId: traineeId, status: PresenceStatus.Absent);
      l.attendance.add(att);
    }

    att.status = status;
    await t.save();
    _loadTrainings();

    // sync to sheet if configured
    if (t.googleSheetUrl.isNotEmpty) {
      SheetsService.syncTrainingToSheet(t);
    }
  }

  // Simple analytics helpers
  double attendancePercentageForTrainee(String trainingId, String traineeId) {
    final t = _box.get(trainingId);
    if (t == null) return 0.0;
    final lessons = t.lessons;
    if (lessons.isEmpty) return 0.0;
    int present = 0;
    int total = lessons.length;
    for (var l in lessons) {
      // Use a simple loop to find attendance record
      Attendance? a;
      try {
        a = l.attendance.firstWhere((att) => att.traineeId == traineeId);
      } catch (e) {
        // If attendance record doesn't exist, skip this lesson
        continue;
      }

      if (a.status == PresenceStatus.Present) present++;
      if (a.status == PresenceStatus.CatchUp)
        present++; // treat catchup as present for percentage
    }
    return (present / total) * 100.0;
  }
}
