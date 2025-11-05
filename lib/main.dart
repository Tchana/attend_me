import 'package:attend_me/pages/pin_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/training.dart';
import 'models/trainee.dart';
import 'models/lesson.dart';
import 'models/attendance.dart';
import 'controllers/training_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TrainingAdapter());
  Hive.registerAdapter(TraineeAdapter());
  Hive.registerAdapter(LessonAdapter());
  Hive.registerAdapter(AttendanceAdapter());
  Hive.registerAdapter(
      PresenceStatusAdapter()); // Add this line to register the PresenceStatus adapter

  await Hive.openBox<Training>('trainings');

  // Initialize controller
  Get.put(TrainingController());

  runApp(GetMaterialApp(home: PinScreen()));
}
