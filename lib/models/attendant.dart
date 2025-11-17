import 'package:hive/hive.dart';
part 'attendant.g.dart';

@HiveType(typeId: 1)
class Attendant extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  Attendant({required this.id, required this.name});
}
