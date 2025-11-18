import 'package:attend_me/pages/program_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/session.dart';
import 'all_sessions_page.dart';

class DashboardPage extends StatelessWidget {
  final ProgramController ctrl = Get.find();
  final AuthController auth = Get.find();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final dt = d.toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  TextStyle _titleStyle(BuildContext context) => Theme.of(context).textTheme.titleLarge ?? TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  TextStyle _subtitleStyle(BuildContext context) => Theme.of(context).textTheme.titleMedium ?? TextStyle(fontSize: 16, color: Colors.grey[700]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${_greeting()},', style: _subtitleStyle(context).copyWith(color: Colors.grey[600])),
          SizedBox(height: 4),
          Obx(() => Text(auth.userName.value?.isNotEmpty == true ? auth.userName.value! : 'User Name', style: _titleStyle(context).copyWith(fontWeight: FontWeight.bold))),
          SizedBox(height: 25),
          Text('Overview', style: _subtitleStyle(context).copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),

          // Cards row
          Obx(() {
            final programs = ctrl.programs;
            final totalSessions = programs.fold<int>(0, (prev, p) => prev + p.sessions.length);
            return Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.deepPurpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.folder_outlined, size: 32, color: Colors.white70),
                          SizedBox(height: 16),
                          Text('${programs.length} Programs', style: TextStyle(fontSize: 18, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.sticky_note_2_outlined, size: 32, color: Colors.white70),
                          SizedBox(height: 16,),
                          Text('$totalSessions Sessions', style: TextStyle(fontSize: 18, color: Colors.white70)),
                                                  ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),

          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent sessions', style: _subtitleStyle(context).copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  try {
                    Get.to(() => AllSessionsPage());
                  } catch (err, st) {
                    Get.snackbar('Navigation error', err.toString(), snackPosition: SnackPosition.BOTTOM);
                    print('Navigation error: $err\n$st');
                  }
                },
                child: Text('See all'),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Make the recent sessions area scrollable if needed
          Expanded(
            child: Obx(() {
              try {
                // Build a list of primitive-only entries to avoid passing Hive objects into JS interop structures
                final List<Map<String, dynamic>> entries = [];
                for (var p in ctrl.programs) {
                  for (final Session s in p.sessions) {
                    entries.add({
                      'programTitle': p.title,
                      'programId': p.id,
                      'sessionTitle': s.title,
                      'sessionDateIso': s.date.toIso8601String(),
                    });
                  }
                }
                entries.sort((a, b) {
                  final DateTime da = DateTime.parse(a['sessionDateIso'] as String);
                  final DateTime db = DateTime.parse(b['sessionDateIso'] as String);
                  return db.compareTo(da);
                });
                final recent = entries.take(5).toList();
                if (recent.isEmpty) return Center(child: Text('No recent sessions'));

                return ListView.separated(
                  itemCount: recent.length + 1,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index < recent.length) {
                      final e = recent[index];
                      final String programId = e['programId'] as String;
                      final String programTitle = e['programTitle'] as String;
                      final String sessionTitle = e['sessionTitle'] as String;
                      final String dateIso = e['sessionDateIso'] as String;
                      final dateStr = _formatDate(DateTime.parse(dateIso));
                      return ListTile(
                        title: Text(sessionTitle),
                        subtitle: Text('$programTitle • $dateStr'),
                        onTap: () {
                          try {
                            Get.to(() => ProgramDetailPage(programId: programId));
                          } catch (err, st) {
                            Get.snackbar('Navigation error', err.toString(), snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 6));
                            print('Navigation error: $err\n$st');
                          }
                        },
                      );
                    }
                    // last item: See all
                    return Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          try {
                            Get.to(() => AllSessionsPage());
                          } catch (err, st) {
                            Get.snackbar('Navigation error', err.toString(), snackPosition: SnackPosition.BOTTOM);
                            print('Navigation error: $err\n$st');
                          }
                        },
                        child: Text('See all'),
                      ),
                    );
                  },
                );
              } catch (err, st) {
                // Capture and report any unexpected runtime issues (useful for Flutter web TypeError)
                Get.snackbar('Error', 'Failed to build recent sessions: ${err.toString()}', snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 6));
                print('Dashboard build error: $err\n$st');
                return Center(child: Text('Unable to load recent sessions'));
              }
            }),
          ),
        ],
      ),
    );
  }
}
