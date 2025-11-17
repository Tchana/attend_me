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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Attendant')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v!.trim().isEmpty ? 'Enter a name' : null,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addAttendant,
              child: Text('Add Attendant'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _addAttendant() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ctrl
            .addAttendant(widget.programId, nameCtrl.text.trim())
            .then((value) {
          Get.back();
          Get.snackbar('Success', 'Attendant added');
        }).catchError((error) {
          Get.back();
          Get.snackbar("Error", error.toString());
        });
        // Close this page and return to the previous one
        // Close current page and return to previous
      } catch (e) {
        Get.snackbar('Error', 'Failed to add attendant: $e');
      }
    }
  }
}
