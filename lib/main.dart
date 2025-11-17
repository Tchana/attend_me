import 'package:attend_me/pages/pin_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/program.dart';
import 'models/attendant.dart';
import 'models/session.dart';
import 'models/attendance.dart';
import 'controllers/program_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ProgramAdapter());
  Hive.registerAdapter(AttendantAdapter());
  Hive.registerAdapter(SessionAdapter());
  Hive.registerAdapter(AttendanceAdapter());
  Hive.registerAdapter(
      PresenceStatusAdapter()); // Add this line to register the PresenceStatus adapter

  await Hive.openBox<Program>('programs');

  // Initialize controller
  Get.put(ProgramController());

  runApp(GetMaterialApp(home: PinScreen()));
}
