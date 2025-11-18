import 'package:attend_me/pages/home_page.dart';
import 'package:attend_me/pages/pin_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/program.dart';
import 'models/attendant.dart';
import 'models/session.dart';
import 'models/attendance.dart';
import 'controllers/program_controller.dart';
import 'controllers/auth_controller.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

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
  await Hive.openBox('authBox');

  // Initialize controllers
  Get.put(ProgramController());
  Get.put(AuthController());

  runApp(
    GetMaterialApp(
      initialRoute: Hive.box('authBox').get('isAuthenticated', defaultValue: false) ? '/home' : '/login',
      debugShowCheckedModeBanner: false,
      title: 'Attend Me',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/signup', page: () => SignupPage()),
        // Keep the PinScreen route in case other parts reference it
        GetPage(name: '/pin', page: () => PinScreen()),
        GetPage(name: '/home', page: () => HomePage()),
      ],
    ),
  );
}
