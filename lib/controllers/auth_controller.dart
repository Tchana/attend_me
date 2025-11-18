import 'package:get/get.dart';
import 'package:hive/hive.dart';

class AuthController extends GetxController {
  late Box _authBox;

  final RxBool isAuthenticated = false.obs;
  final RxnString userEmail = RxnString();
  final RxnString userName = RxnString();

  @override
  void onInit() {
    super.onInit();
    _authBox = Hive.box('authBox');
    isAuthenticated.value = _authBox.get('isAuthenticated', defaultValue: false) as bool;
    userEmail.value = _authBox.get('userEmail') as String?;
    userName.value = _authBox.get('userName') as String?;
  }

  Future<bool> signup(String name, String email, String password) async {
    // NOTE: This is a minimal local signup for demo only. Do NOT store passwords in plain text in production.
    await _authBox.put('userEmail', email);
    await _authBox.put('userName', name);
    await _authBox.put('isAuthenticated', true);

    userEmail.value = email;
    userName.value = name;
    isAuthenticated.value = true;
    return true;
  }

  Future<bool> login(String email, String password) async {
    // Minimal local login: succeeds if email matches stored email.
    final storedEmail = _authBox.get('userEmail') as String? ?? 'valdotnv@gmail.com';
    if (storedEmail != null && storedEmail == email) {
      await _authBox.put('isAuthenticated', true);
      isAuthenticated.value = true;
      userEmail.value = email;
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authBox.put('isAuthenticated', false);
    isAuthenticated.value = false;
    userEmail.value = null;
    userName.value = null;
  }
}

