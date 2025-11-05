import 'package:hive/hive.dart';
import 'lesson.dart';
import 'trainee.dart';

part 'training.g.dart';

@HiveType(typeId: 0)
class Training extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  // Google Sheet link (optional)
  @HiveField(3)
  String googleSheetUrl;

  @HiveField(4)
  List<Trainee> trainees;

  @HiveField(5)
  List<Lesson> lessons;

  Training({
    required this.id,
    required this.title,
    this.description = '',
    this.googleSheetUrl = '',
    List<Trainee>? trainees,
    List<Lesson>? lessons,
  })  : trainees = trainees ?? [],
        lessons = lessons ?? [];
}
