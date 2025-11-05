import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/training_controller.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/attendance.dart';

class AnalyticsPage extends StatelessWidget {
  final String trainingId;
  final ctrl = Get.find<TrainingController>();

  AnalyticsPage({required this.trainingId});

  @override
  Widget build(BuildContext context) {
    final training = ctrl.trainings.firstWhere((t) => t.id == trainingId);

    // Calculate overall statistics
    int presentCount = 0;
    int absentCount = 0;
    int catchupCount = 0;

    for (var lesson in training.lessons) {
      for (var attendance in lesson.attendance) {
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
      appBar: AppBar(title: Text('Analytics - ${training.title}')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
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
                        color: Colors.white,
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
                        color: Colors.white,
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
                        color: Colors.white,
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
            // Individual trainee statistics
            Expanded(
              child: ListView(
                children: training.trainees.map((tr) {
                  double pct =
                      ctrl.attendancePercentageForTrainee(trainingId, tr.id);
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
