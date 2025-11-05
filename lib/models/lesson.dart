import 'package:hive/hive.dart';
import 'attendance.dart';
part 'lesson.g.dart';

@HiveType(typeId: 2)
class Lesson extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime date;

  // true = new chapter, false = continuation
  @HiveField(3)
  bool isNewChapter;

  @HiveField(4)
  List<Attendance> attendance;

  Lesson({
    required this.id,
    required this.title,
    required this.date,
    this.isNewChapter = true,
    List<Attendance>? attendance,
  }) : attendance = attendance ?? [];
}
