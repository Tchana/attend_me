import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';

class CreateProgramPage extends StatelessWidget {
  final ProgramController ctrl = Get.find();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final sheetCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Program'),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Description')),
            TextField(controller: sheetCtrl, decoration: InputDecoration(labelText: 'Google Sheet URL (optional)')),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Create'),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  Get.snackbar('Error', 'Title is required');
                  return;
                }
                ctrl.createProgram(title, desc: descCtrl.text.trim(), sheetUrl: sheetCtrl.text.trim());
                Get.back();
              },
            )
          ],
        ),
      ),
    );
  }
}
