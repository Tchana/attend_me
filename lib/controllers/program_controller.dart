import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/program.dart';
import '../models/attendant.dart';
import '../models/session.dart';
import '../models/attendance.dart';
import '../services/sheets_service.dart';

class ProgramController extends GetxController {
  final Box<Program> _box = Hive.box<Program>('programs');
  final programs = <Program>[].obs;

  final uuid = Uuid();

  @override
  void onInit() {
    super.onInit();
    _loadPrograms();
  }

  void _loadPrograms() {
    programs.assignAll(_box.values.toList());
  }

  Future<void> createProgram(String title,
      {String desc = '', String sheetUrl = ''}) async {
    final t = Program(
        id: uuid.v4(),
        title: title,
        description: desc,
        googleSheetUrl: sheetUrl);
    await _box.put(t.id, t);
    _loadPrograms();
  }

  Future<void> deleteProgram(String id) async {
    await _box.delete(id);
    _loadPrograms();
  }

  Future<void> addImportedProgram(Program program) async {
    await _box.put(program.id, program);
    _loadPrograms();
  }

  Future<void> updateProgram(String id, String newTitle, String newDescription) async {
    final t = _box.get(id);
    if (t == null) return;
    t.title = newTitle;
    t.description = newDescription;
    await t.save();
    _loadPrograms();

    // If Google Sheet is configured, try to sync
    if (t.googleSheetUrl.isNotEmpty) {
      SheetsService.syncProgramToSheet(t);
    }
  }

  Future<void> addAttendant(String programId, String name) async {
    final t = _box.get(programId);
    if (t == null) return;
    final newAttendant = Attendant(id: uuid.v4(), name: name);
    t.attendants.add(newAttendant);

    // Create attendance records for all existing sessions
    for (var session in t.sessions) {
      session.attendance.add(
          Attendance(attendantId: newAttendant.id, status: PresenceStatus.Absent));
    }

    await t.save();
    _loadPrograms();
  }

  Future<void> removeAttendant(String programId, String attendantId) async {
    final t = _box.get(programId);
    if (t == null) return;
    t.attendants.removeWhere((tr) => tr.id == attendantId);
    // also remove attendance entries
    for (var session in t.sessions) {
      session.attendance.removeWhere((a) => a.attendantId == attendantId);
    }
    await t.save();
    _loadPrograms();
  }

  Future<void> addSession(
      String programId, String title, DateTime date, bool isNewChapter,
      {bool recurringWeekly = false, int weeks = 0}) async {
    final t = _box.get(programId);
    if (t == null) return;
    final session = Session(
        id: uuid.v4(), title: title, date: date, isNewChapter: isNewChapter);
    // create initial empty attendance for all attendants (default Absent)
    for (var tr in t.attendants) {
      session.attendance
          .add(Attendance(attendantId: tr.id, status: PresenceStatus.Absent));
    }
    t.sessions.add(session);
    // optionally create recurring weekly sessions
    if (recurringWeekly && weeks > 1) {
      DateTime nextDate = date;
      for (int i = 1; i < weeks; i++) {
        nextDate = nextDate.add(Duration(days: 7));
        final l2 = Session(
            id: uuid.v4(),
            title: title + ' (Week ${i + 1})',
            date: nextDate,
            isNewChapter: isNewChapter);
        for (var tr in t.attendants) {
          l2.attendance
              .add(Attendance(attendantId: tr.id, status: PresenceStatus.Absent));
        }
        t.sessions.add(l2);
      }
    }

    await t.save();
    _loadPrograms();

    // If Google Sheet is configured, try to sync
    if (t.googleSheetUrl.isNotEmpty) {
      SheetsService.syncProgramToSheet(t); // fire-and-forget
    }
  }

  Future<void> updateAttendance(String programId, String sessionId,
      String attendantId, PresenceStatus status) async {
    final t = _box.get(programId);
    if (t == null) return;
    final l = t.sessions.firstWhere((x) => x.id == sessionId);

    // Find existing attendance record or create new one
    Attendance? att;
    try {
      att = l.attendance.firstWhere((a) => a.attendantId == attendantId);
    } catch (e) {
      // If attendance record doesn't exist, create a new one
      att = Attendance(attendantId: attendantId, status: PresenceStatus.Absent);
      l.attendance.add(att);
    }

    att.status = status;
    await t.save();
    _loadPrograms();

    // sync to sheet if configured
    if (t.googleSheetUrl.isNotEmpty) {
      SheetsService.syncProgramToSheet(t);
    }
  }

  // Simple analytics helpers
  double attendancePercentageForAttendant(String programId, String attendantId) {
    final t = _box.get(programId);
    if (t == null) return 0.0;
    final sessions = t.sessions;
    if (sessions.isEmpty) return 0.0;
    int present = 0;
    int total = sessions.length;
    for (var l in sessions) {
      // Use a simple loop to find attendance record
      Attendance? a;
      try {
        a = l.attendance.firstWhere((att) => att.attendantId == attendantId);
      } catch (e) {
        // If attendance record doesn't exist, skip this session
        continue;
      }

      if (a.status == PresenceStatus.Present) present++;
      if (a.status == PresenceStatus.CatchUp)
        present++; // treat catchup as present for percentage
    }
    return (present / total) * 100.0;
  }
}
