import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';

class AddTraineePage extends StatefulWidget {
  final String trainingId;
  AddTraineePage({required this.trainingId});

  @override
  _AddTraineePageState createState() => _AddTraineePageState();
}

class _AddTraineePageState extends State<AddTraineePage> {
  final ctrl = Get.find<TrainingController>();
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Trainee')),
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
              onPressed: _addTrainee,
              child: Text('Add Trainee'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _addTrainee() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ctrl
            .addTrainee(widget.trainingId, nameCtrl.text.trim())
            .then((value) {
          Get.back();
          Get.snackbar('Success', 'Trainee added');
        }).catchError((error) {
          Get.back();
          Get.snackbar("Error", error.toString());
        });
        // Close this page and return to the previous one
        // Close current page and return to previous
      } catch (e) {
        Get.snackbar('Error', 'Failed to add trainee: $e');
      }
    }
  }
}
