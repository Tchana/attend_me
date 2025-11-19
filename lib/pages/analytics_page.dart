import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';
import '../services/csv_service.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/attendance.dart';

class AnalyticsPage extends StatelessWidget {
  final String programId;
  final ctrl = Get.find<ProgramController>();

  AnalyticsPage({required this.programId});

  @override
  Widget build(BuildContext context) {
    final program = ctrl.programs.firstWhere((t) => t.id == programId);

    // Calculate overall statistics
    int presentCount = 0;
    int absentCount = 0;
    int catchupCount = 0;

    for (var session in program.sessions) {
      for (var attendance in session.attendance) {
        if (attendance.status == PresenceStatus.Present) {
          presentCount++;
        } else if (attendance.status == PresenceStatus.Absent) {
          absentCount++;
        } else if (attendance.status == PresenceStatus.CatchUp) {
          catchupCount++;
        }
      }
    }

    int totalCount = presentCount + absentCount + catchupCount;

    return Scaffold(
      backgroundColor: Color(0xFFEEEEEE),
      appBar: AppBar(
        title: Text('Analytics - ${program.title}'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () => CsvService.exportAnalyticsCsv(programId),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(height: 12),
            // Overall statistics chart
            Container(
              height: 200,
              padding: EdgeInsets.all(16),
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: presentCount.toDouble(),
                      title:
                          'Present\n${totalCount > 0 ? (presentCount / totalCount * 100).toStringAsFixed(1) : "0"}%',
                      color: Colors.green,
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F9F9),
                      ),
                    ),
                    PieChartSectionData(
                      value: absentCount.toDouble(),
                      title:
                          'Absent\n${totalCount > 0 ? (absentCount / totalCount * 100).toStringAsFixed(1) : "0"}%',
                      color: Colors.red,
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F9F9),
                      ),
                    ),
                    PieChartSectionData(
                      value: catchupCount.toDouble(),
                      title:
                          'Catchup\n${totalCount > 0 ? (catchupCount / totalCount * 100).toStringAsFixed(1) : "0"}%',
                      color: Colors.orange,
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9F9F9),
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Present'),
                SizedBox(width: 20),
                _buildLegendItem(Colors.red, 'Absent'),
                SizedBox(width: 20),
                _buildLegendItem(Colors.orange, 'Catchup'),
              ],
            ),
            SizedBox(height: 20),
            // Individual attendant statistics
            Expanded(
              child: ListView(
                children: program.attendants.map((tr) {
                  double pct =
                      ctrl.attendancePercentageForAttendant(programId, tr.id);
                  return Card(
                    child: ListTile(
                      title: Text(tr.name),
                      subtitle: LinearPercentIndicator(
                        lineHeight: 14.0,
                        percent: (pct / 100).clamp(0.0, 1.0),
                        center: Text("${pct.toStringAsFixed(1)}%"),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
