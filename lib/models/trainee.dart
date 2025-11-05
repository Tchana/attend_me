import 'package:hive/hive.dart';
part 'trainee.g.dart';

@HiveType(typeId: 1)
class Trainee extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  Trainee({required this.id, required this.name});
}
