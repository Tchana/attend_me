import 'package:attend_me/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class PinScreen extends StatefulWidget {
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pinCtrl = TextEditingController();
  String? savedPin;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPin = prefs.getString('pin');
    });
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin', pin);
  }

  @override
  Widget build(BuildContext context) {
    bool firstTime = savedPin == null;
    return Scaffold(
      appBar: AppBar(title: Text(firstTime ? 'Set PIN' : 'Enter PIN')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(labelText: 'PIN'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text(firstTime ? 'Save PIN' : 'Enter'),
              onPressed: () async {
                if (_pinCtrl.text.length != 4) {
                  Get.snackbar('Error', 'PIN must be 4 digits');
                  return;
                }
                if (firstTime) {
                  await _savePin(_pinCtrl.text);
                  // Navigate directly to HomePage instead of MyApp
                  Get.offAll(() => HomePage());
                } else {
                  if (_pinCtrl.text == savedPin) {
                    // Navigate directly to HomePage instead of MyApp
                    Get.offAll(() => HomePage());
                  } else {
                    Get.snackbar('Error', 'Incorrect PIN');
                  }
                }
              },
            )
          ],
        ),
      ),
    );
  }
}