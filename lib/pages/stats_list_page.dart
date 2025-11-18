import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/program_controller.dart';
import '../models/attendance.dart';
import 'package:fl_chart/fl_chart.dart';

enum StatsPeriod { day, week, month, custom }

class StatsListPage extends StatefulWidget {
  @override
  _StatsListPageState createState() => _StatsListPageState();
}

class _StatsListPageState extends State<StatsListPage> {
  final ProgramController ctrl = Get.find();

  String? _selectedProgramId;
  StatsPeriod _period = StatsPeriod.day;
  DateTime? _customStart;
  DateTime? _customEnd;

  void _onProgramChanged(String? id) {
    setState(() {
      _selectedProgramId = id;
    });
  }

  void _onPeriodChanged(StatsPeriod p) {
    setState(() {
      _period = p;
      // reset custom range when switching off custom
      if (p != StatsPeriod.custom) {
        _customStart = null;
        _customEnd = null;
      }
    });
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = _customStart ?? DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
    final initialEnd = _customEnd ?? DateTime(now.year, now.month, now.day);

    final start = await showDatePicker(
      context: context,
      initialDate: initialStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (start == null) return;
    final end = await showDatePicker(
      context: context,
      initialDate: initialEnd.isBefore(start) ? start : initialEnd,
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (end == null) return;
    setState(() {
      _customStart = DateTime(start.year, start.month, start.day);
      _customEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    });
  }

  bool _sessionInPeriod(DateTime sessionDate, StatsPeriod period) {
    final now = DateTime.now();
    final d = sessionDate.toLocal();
    switch (period) {
      case StatsPeriod.day:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case StatsPeriod.week:
        final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return d.isAtLeast(weekStart) && d.isAtMost(weekEnd);
      case StatsPeriod.month:
        return d.year == now.year && d.month == now.month;
      case StatsPeriod.custom:
        if (_customStart == null || _customEnd == null) return false;
        return d.isAtLeast(_customStart!) && d.isAtMost(_customEnd!);
    }
  }

  Map<String, dynamic> _computeStatsForProgram(String programId) {
    final p = ctrl.programs.firstWhere((x) => x.id == programId);
    // collect sessions in period
    final sessions = p.sessions.where((s) => _sessionInPeriod(s.date, _period)).toList();

    int present = 0, absent = 0, catchup = 0;

    final Map<String, int> attendantPresent = {};
    final Map<String, int> attendantTotal = {};

    for (var att in p.attendants) {
      attendantPresent[att.id] = 0;
      attendantTotal[att.id] = 0;
    }

    for (var s in sessions) {
      for (var a in s.attendance) {
        attendantTotal[a.attendantId] = (attendantTotal[a.attendantId] ?? 0) + 1;
        if (a.status == PresenceStatus.Present) {
          present++;
          attendantPresent[a.attendantId] = (attendantPresent[a.attendantId] ?? 0) + 1;
        } else if (a.status == PresenceStatus.Absent) {
          absent++;
        } else if (a.status == PresenceStatus.CatchUp) {
          catchup++;
          attendantPresent[a.attendantId] = (attendantPresent[a.attendantId] ?? 0) + 1;
        }
      }
    }

    final totalRecords = present + absent + catchup;

    // compute per-attendant percentage
    final List<Map<String, dynamic>> perAtt = [];
    for (var att in p.attendants) {
      final tot = attendantTotal[att.id] ?? 0;
      final pres = attendantPresent[att.id] ?? 0;
      final pct = tot == 0 ? 0.0 : (pres / tot) * 100.0;
      perAtt.add({'id': att.id, 'name': att.name, 'percent': pct, 'present': pres, 'total': tot});
    }

    return {
      'present': present,
      'absent': absent,
      'catchup': catchup,
      'totalRecords': totalRecords,
      'perAttendant': perAtt,
      'sessionsCount': sessions.length,
    };
  }

  Widget _buildCharts(Map<String, dynamic> stats) {
    final int present = stats['present'] as int;
    final int absent = stats['absent'] as int;
    final int catchup = stats['catchup'] as int;
    final total = (present + absent + catchup);

    final sections = <PieChartSectionData>[];
    if (total > 0) {
      if (present > 0) sections.add(PieChartSectionData(value: present.toDouble(), color: Colors.green, title: '${((present/total)*100).toStringAsFixed(0)}%'));
      if (absent > 0) sections.add(PieChartSectionData(value: absent.toDouble(), color: Colors.red, title: '${((absent/total)*100).toStringAsFixed(0)}%'));
      if (catchup > 0) sections.add(PieChartSectionData(value: catchup.toDouble(), color: Colors.orange, title: '${((catchup/total)*100).toStringAsFixed(0)}%'));
    }

    // Bar chart data: per-attendant percentages
    final perAtt = stats['perAttendant'] as List<dynamic>;
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < perAtt.length; i++) {
      final pct = (perAtt[i]['percent'] as double).clamp(0.0, 100.0);
      barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: pct, color: Colors.blueAccent, width: 12)], showingTooltipIndicators: [0]));
    }

    return Column(
      children: [
        SizedBox(height: 12),
        if (total > 0)
          SizedBox(
            height: 140,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(sections: sections, centerSpaceRadius: 24, sectionsSpace: 2),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attendance % by person', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: barGroups,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final programs = ctrl.programs;
      if (programs.isEmpty) return Center(child: Text('No programs to show stats for'));

      // default select first program if none
      _selectedProgramId ??= programs.first.id;

      final selectedProgram = programs.firstWhere((p) => p.id == _selectedProgramId, orElse: () => programs.first);
      final stats = _computeStatsForProgram(selectedProgram.id);

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Program selector
            DropdownButtonFormField<String>(
              initialValue: _selectedProgramId,
              decoration: InputDecoration(labelText: 'Program'),
              items: programs.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))).toList(),
              onChanged: _onProgramChanged,
            ),
            SizedBox(height: 12),

            // Period filter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text('Day'),
                  selected: _period == StatsPeriod.day,
                  onSelected: (_) => _onPeriodChanged(StatsPeriod.day),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Week'),
                  selected: _period == StatsPeriod.week,
                  onSelected: (_) => _onPeriodChanged(StatsPeriod.week),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Month'),
                  selected: _period == StatsPeriod.month,
                  onSelected: (_) => _onPeriodChanged(StatsPeriod.month),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Custom'),
                  selected: _period == StatsPeriod.custom,
                  onSelected: (_) async {
                    _onPeriodChanged(StatsPeriod.custom);
                    await _pickCustomRange(context);
                  },
                ),
              ],
            ),
            if (_period == StatsPeriod.custom && _customStart != null && _customEnd != null) ...[
              SizedBox(height: 8),
              Text('Range: ${_customStart!.toLocal().toIso8601String().split("T").first} → ${_customEnd!.toLocal().toIso8601String().split("T").first}'),
            ],
            SizedBox(height: 16),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text('Present', style: TextStyle(color: Colors.green)),
                          SizedBox(height: 8),
                          Text('${stats['present']}'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text('Absent', style: TextStyle(color: Colors.red)),
                          SizedBox(height: 8),
                          Text('${stats['absent']}'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text('CatchUp', style: TextStyle(color: Colors.orange)),
                          SizedBox(height: 8),
                          Text('${stats['catchup']}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // charts for the selected period
            _buildCharts(stats),
            SizedBox(height: 16),

            Text('Sessions in period: ${stats['sessionsCount']}', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: (stats['perAttendant'] as List).length,
                itemBuilder: (_, i) {
                  final row = (stats['perAttendant'] as List)[i] as Map<String, dynamic>;
                  final pct = row['percent'] as double;
                  return Card(
                    child: ListTile(
                      title: Text(row['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 6),
                          LinearProgressIndicator(value: pct / 100.0),
                          SizedBox(height: 6),
                          Text('${pct.toStringAsFixed(1)}% (${row['present']}/${row['total']})'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

// small DateTime helpers used above
extension DateCompare on DateTime {
  bool isAtLeast(DateTime other) => !this.isBefore(other);
  bool isAtMost(DateTime other) => !this.isAfter(other);
}
