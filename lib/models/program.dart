import 'package:hive/hive.dart';
import 'session.dart';
import 'attendant.dart';

part 'program.g.dart';

@HiveType(typeId: 0)
class Program extends HiveObject {
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
  List<Attendant> attendants;

  @HiveField(5)
  List<Session> sessions;

  Program({
    required this.id,
    required this.title,
    this.description = '',
    this.googleSheetUrl = '',
    List<Attendant>? attendants,
    List<Session>? sessions,
  })  : attendants = attendants ?? [],
        sessions = sessions ?? [];
}
