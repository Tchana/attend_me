import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';

class AddAttendantPage extends StatefulWidget {
  final String programId;
  AddAttendantPage({required this.programId});

  @override
  _AddAttendantPageState createState() => _AddAttendantPageState();
}

class _AddAttendantPageState extends State<AddAttendantPage> {
  final ctrl = Get.find<ProgramController>();
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEEEE),
      appBar: AppBar(title: Text('Add Attendant')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            SizedBox(
              height: 60,
              child: TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v!.trim().isEmpty ? 'Enter a name' : null,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _addAttendant,
              child: _isLoading
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF9F9F9))))
                  : Text('Add Attendant'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _addAttendant() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ctrl.addAttendant(widget.programId, nameCtrl.text.trim());
      setState(() => _isLoading = false);
      Get.back();
      Get.snackbar('Success', 'Attendant added', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'Failed to add attendant: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent, colorText: Color(0xFFF9F9F9));
    }
  }
}
