import 'package:hive/hive.dart';
part 'attendance.g.dart';

@HiveType(typeId: 3)
enum PresenceStatus {
  @HiveField(0)
  Present,
  @HiveField(1)
  Absent,
  @HiveField(2)
  CatchUp,
}

@HiveType(typeId: 4)
class Attendance extends HiveObject {
  @HiveField(0)
  String attendantId;

  @HiveField(1)
  PresenceStatus status;

  Attendance({required this.attendantId, required this.status});
}
