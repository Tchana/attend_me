import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';

class AllSessionsPage extends StatelessWidget {
  final ProgramController ctrl = Get.find();

  String _formatDateIso(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gather all sessions from all programs (primitive-only entries)
    final allSessions = <Map<String, String>>[];
    for (var p in ctrl.programs) {
      for (var s in p.sessions) {
        allSessions.add({'programTitle': p.title, 'sessionTitle': s.title, 'sessionDateIso': s.date.toIso8601String()});
      }
    }
    allSessions.sort((a, b) => (b['sessionDateIso']!).compareTo(a['sessionDateIso']!));

    return Scaffold(
      backgroundColor: Color(0xFFE2E2E2),
      appBar: AppBar(title: Text('All Sessions')),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: allSessions.length,
        itemBuilder: (_, i) {
          final entry = allSessions[i];
          final sessionTitle = entry['sessionTitle']!;
          final programTitle = entry['programTitle']!;
          final dateIso = entry['sessionDateIso']!;
          return Card(
            child: ListTile(
              title: Text(sessionTitle),
              subtitle: Text('$programTitle • ${_formatDateIso(dateIso)}'),
            ),
          );
        },
      ),
    );
  }
}
