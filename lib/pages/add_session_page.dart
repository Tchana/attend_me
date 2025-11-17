import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';

class AddSessionPage extends StatefulWidget {
  final String programId;
  AddSessionPage({required this.programId});
  @override
  _AddSessionPageState createState() => _AddSessionPageState();
}

class _AddSessionPageState extends State<AddSessionPage> {
  final titleCtrl = TextEditingController();
  DateTime selected = DateTime.now();
  bool isNewChapter = true;
  bool recurring = false;
  int weeks = 1;
  final ctrl = Get.find<ProgramController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Session')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Session title')),
            SizedBox(height: 8),
            Row(children: [
              const Text('Date: '),
              TextButton(
                child: Text('${selected.toLocal()}'.split(' ')[0]),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: selected,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => selected = d);
                },
              )
            ]),
            SwitchListTile(
              title: const Text('New chapter?'),
              value: isNewChapter,
              onChanged: (v) => setState(() => isNewChapter = v),
            ),
            SwitchListTile(
              title: const Text('Recurring weekly?'),
              value: recurring,
              onChanged: (v) => setState(() => recurring = v),
            ),
            if (recurring)
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Weeks (including first)'),
                keyboardType: TextInputType.number,
                onChanged: (s) => weeks = int.tryParse(s) ?? 1,
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addSession,
              child: const Text('Create Session'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _addSession() async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      Get.snackbar('Error', 'Title required');
      return;
    }

    if (recurring && weeks < 1) {
      Get.snackbar('Error', 'Weeks must be at least 1');
      return;
    }

    try {
      await ctrl
          .addSession(widget.programId, title, selected, isNewChapter,
              recurringWeekly: recurring, weeks: weeks)
          .then((value) {
        // Close this page and return to the previous one
        Get.back();
        Get.snackbar('Success', 'Session created');

      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to create session: $e');
    }
  }
}
