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
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
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
            // Recent sessions container: white card with rounded corners
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent sessions', style: _subtitleStyle(context).copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
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
                    Expanded(
                      child: Obx(() {
                        try {
                          // Build a list of primitive-only entries to avoid passing Hive objects into JS interop structures
                          final List<Map<String, dynamic>> entries = [];
                          for (var p in ctrl.programs) {
                            for (final Session s in p.sessions) {
                              entries.add({
                                'sessionId': s.id,
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

                          return ListView.builder(
                            itemCount: recent.length,
                            itemBuilder: (context, index) {
                              final e = recent[index];
                              final String sessionId = e['sessionId'] as String? ?? '${index}';
                              final String programId = e['programId'] as String;
                              final String programTitle = e['programTitle'] as String;
                              final String sessionTitle = e['sessionTitle'] as String;
                              final String dateIso = e['sessionDateIso'] as String;
                              final dateStr = _formatDate(DateTime.parse(dateIso));

                              final Widget child = (index == 0)
                                  ? ListTile(
                                      key: ValueKey(sessionId),
                                      title: Text(sessionTitle),
                                      subtitle: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('$programTitle'),
                                          Row(
                                            children: [
                                              Text('$dateStr'),
                                              SizedBox(width: 10,),
                                              Icon(Icons.chevron_right_outlined, size: 16, color: Colors.grey[600])
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        try {
                                          Get.to(() => ProgramDetailPage(programId: programId));
                                        } catch (err, st) {
                                          Get.snackbar('Navigation error', err.toString(), snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 6));
                                          print('Navigation error: $err\n$st');
                                        }
                                      },
                                    )
                                  : Column(
                                      key: ValueKey(sessionId),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Divider(
                                          height: 2,
                                          thickness: 0.5,
                                          color: Colors.grey,
                                        ),
                                        ListTile(
                                          title: Text(sessionTitle),
                                          subtitle: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('$programTitle'),
                                              Row(
                                                children: [
                                                  Text('$dateStr'),
                                                  SizedBox(width: 10,),
                                                  Icon(Icons.chevron_right_outlined, size: 16, color: Colors.grey[600])
                                                ],
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            try {
                                              Get.to(() => ProgramDetailPage(programId: programId));
                                            } catch (err, st) {
                                              Get.snackbar('Navigation error', err.toString(), snackPosition: SnackPosition.BOTTOM, duration: Duration(seconds: 6));
                                              print('Navigation error: $err\n$st');
                                            }
                                          },
                                        ),
                                      ],
                                    );

                              // AnimatedSwitcher to animate insertions/changes (fade + slide)
                              return AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  final offsetAnimation = Tween<Offset>(begin: Offset(0, 0.05), end: Offset.zero).animate(animation);
                                  return FadeTransition(opacity: animation, child: SlideTransition(position: offsetAnimation, child: child));
                                },
                                child: child,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
