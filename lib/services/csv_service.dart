import 'package:attend_me/models/attendance.dart';
import 'package:attend_me/models/program.dart';
import 'package:attend_me/models/attendant.dart';
import 'package:attend_me/models/session.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/program_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'download_helper.dart';

class CsvService {
  static Future<void> exportProgramToCsv(String programId) async {
    try {
      final ctrl = Get.find<ProgramController>();

      // Check if program exists
      if (ctrl.programs.isEmpty) {
        throw Exception('No programs found');
      }

      final t = ctrl.programs.firstWhere(
        (tr) => tr.id == programId,
        orElse: () => throw Exception('Program with ID $programId not found'),
      );

      // Ask user where they want to save the file
      final selectedDirectory = await _pickDirectory();
      if (selectedDirectory == null) {
        // User cancelled the directory selection, fallback to previous behavior
        _exportAsCsvWithFallback(t);
        return;
      }

      // Always export to Excel format when user clicks export button
      await _exportToExcelDirectory(t, selectedDirectory);
    } catch (e) {
      print('Error exporting program to Excel: $e');
      Get.snackbar('Export Error', 'Failed to export: $e');
    }
  }

  static Future<void> exportAnalyticsCsv(String programId) async {
    try {
      final ctrl = Get.find<ProgramController>();
      final program =
          ctrl.programs.firstWhere((t) => t.id == programId, orElse: () {
        throw Exception('Program with ID $programId not found');
      });

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

      final totalRecords = presentCount + absentCount + catchupCount;

      final rows = <List<String>>[];
      rows.add(['Type', 'Present', 'Absent', 'CatchUp', 'Total']);
      rows.add([
        'Overall',
        presentCount.toString(),
        absentCount.toString(),
        catchupCount.toString(),
        totalRecords.toString()
      ]);
      rows.add([]);
      rows.add(
          ['Attendant', 'Present', 'Absent', 'CatchUp', 'Attendance Percent']);

      for (var attendant in program.attendants) {
        int attendantPresent = 0;
        int attendantAbsent = 0;
        int attendantCatchup = 0;

        for (var session in program.sessions) {
          final att = session.attendance.firstWhere(
              (a) => a.attendantId == attendant.id,
              orElse: () =>
                  Attendance(attendantId: attendant.id, status: PresenceStatus.Absent));
          if (att.status == PresenceStatus.Present) {
            attendantPresent++;
          } else if (att.status == PresenceStatus.Absent) {
            attendantAbsent++;
          } else if (att.status == PresenceStatus.CatchUp) {
            attendantCatchup++;
          }
        }

        final totalSessions = program.sessions.length;
        final percent = totalSessions == 0
            ? 0.0
            : ((attendantPresent + attendantCatchup) / totalSessions) * 100;

        rows.add([
          attendant.name,
          attendantPresent.toString(),
          attendantAbsent.toString(),
          attendantCatchup.toString(),
          percent.toStringAsFixed(1)
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final sanitizedTitle =
          program.title.replaceAll(RegExp(r'[^\w\s-]+'), '_').trim();
      final fileName = (sanitizedTitle.isEmpty ? 'program' : sanitizedTitle) +
          '_analytics.csv';
      final savedPath = await _saveTextFile(fileName, csv);

      if (savedPath != null) {
        Get.snackbar('Export Successful',
            'Analytics data saved to:\n$savedPath\n\nYou can open it in any spreadsheet application.',
            duration: Duration(seconds: 12));
      } else {
        await Clipboard.setData(ClipboardData(text: csv));
        Get.snackbar('Export Successful',
            'Unable to write file. CSV data copied to clipboard instead.',
            duration: Duration(seconds: 12));
      }
    } catch (e) {
      print('Error exporting analytics CSV: $e');
      Get.snackbar('Export Error', 'Failed to export analytics: $e');
    }
  }

  /// Prompt the user to select a directory and save the analytics CSV there.
  /// If the user cancels selection, the export is aborted.
  static Future<void> exportAnalyticsCsvToDirectory(String programId) async {
    try {
      final ctrl = Get.find<ProgramController>();
      final program = ctrl.programs.firstWhere((t) => t.id == programId, orElse: () {
        throw Exception('Program with ID $programId not found');
      });

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

      final rows = <List<String>>[];
      rows.add(['Type', 'Present', 'Absent', 'CatchUp', 'Total']);
      rows.add([
        'Overall',
        presentCount.toString(),
        absentCount.toString(),
        catchupCount.toString(),
        (presentCount + absentCount + catchupCount).toString()
      ]);
      rows.add([]);
      rows.add(['Attendant', 'Present', 'Absent', 'CatchUp', 'Attendance Percent']);

      for (var attendant in program.attendants) {
        int attendantPresent = 0;
        int attendantAbsent = 0;
        int attendantCatchup = 0;

        for (var session in program.sessions) {
          final att = session.attendance.firstWhere(
              (a) => a.attendantId == attendant.id,
              orElse: () => Attendance(attendantId: attendant.id, status: PresenceStatus.Absent));
          if (att.status == PresenceStatus.Present) {
            attendantPresent++;
          } else if (att.status == PresenceStatus.Absent) {
            attendantAbsent++;
          } else if (att.status == PresenceStatus.CatchUp) {
            attendantCatchup++;
          }
        }

        final totalSessions = program.sessions.length;
        final percent = totalSessions == 0
            ? 0.0
            : ((attendantPresent + attendantCatchup) / totalSessions) * 100;

        rows.add([
          attendant.name,
          attendantPresent.toString(),
          attendantAbsent.toString(),
          attendantCatchup.toString(),
          percent.toStringAsFixed(1)
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final sanitizedTitle = program.title.replaceAll(RegExp(r'[^\w\s-]+'), '_').trim();
      final fileName = (sanitizedTitle.isEmpty ? 'program' : sanitizedTitle) + '_analytics.csv';

      // Prompt user to pick a directory
      final selectedDir = await _pickDirectory();
      if (selectedDir == null || selectedDir.isEmpty) {
        Get.snackbar('Export cancelled', 'No folder selected for export');
        return;
      }

      try {
        final file = File('$selectedDir/$fileName');
        await file.writeAsString(csv);
        Get.snackbar('Export Successful', 'Analytics data saved to:\n${file.path}', duration: Duration(seconds: 12));
        // Try to open
        try {
          if (await file.exists()) {
            final uri = Uri.file(file.path);
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }
        } catch (e) {
          print('Could not open exported file: $e');
        }
      } catch (e) {
        print('Error writing analytics CSV to selected directory: $e');
        // Fallback copy to clipboard
        try {
          await Clipboard.setData(ClipboardData(text: csv));
          Get.snackbar('Export fallback', 'Unable to write file. CSV copied to clipboard.');
        } catch (e2) {
          Get.snackbar('Export Error', 'Failed to export analytics: $e');
        }
      }
    } catch (e) {
      print('Error in exportAnalyticsCsvToDirectory: $e');
      Get.snackbar('Export Error', 'Failed to export analytics: $e');
    }
  }

  static Future<void> importProgramFromCsv() async {
    try {
      final ctrl = Get.find<ProgramController>();
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: 'Select attendance CSV',
      );
      if (fileResult == null || fileResult.files.isEmpty) return;

      final path = fileResult.files.single.path;
      if (path == null) {
        throw Exception('Unable to read selected file path');
      }

      final csvContent = await File(path).readAsString();
      final rows = const CsvToListConverter().convert(csvContent);

      if (rows.length < 2) {
        throw Exception('CSV must include at least one attendant row');
      }

      final headerRow =
          rows.first.map((cell) => cell.toString().trim()).toList();

      if (headerRow.isEmpty || headerRow.first.toLowerCase() != 'attendant') {
        throw Exception('First column must be labeled "Attendant"');
      }

      final sessionHeaders = headerRow.length > 1 ? headerRow.sublist(1) : [];

      final sessions = <Session>[];
      for (var i = 0; i < sessionHeaders.length; i++) {
        final parsedHeader = _parseSessionHeader(sessionHeaders[i], i);
        sessions.add(Session(
            id: ctrl.uuid.v4(),
            title: parsedHeader.title,
            date: parsedHeader.date,
            isNewChapter: i == 0,
            attendance: []));
      }

      final attendants = <Attendant>[];

      for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        if (row.isEmpty) continue;
        final name = row.first?.toString().trim() ?? '';
        if (name.isEmpty) continue;

        final attendant = Attendant(id: ctrl.uuid.v4(), name: name);
        attendants.add(attendant);

        for (var sessionIndex = 0; sessionIndex < sessions.length; sessionIndex++) {
          final cellIndex = sessionIndex + 1;
          final value =
              cellIndex < row.length ? row[cellIndex]?.toString() ?? '' : '';
          final status = _statusFromCell(value);
          sessions[sessionIndex].attendance.add(
              Attendance(attendantId: attendant.id, status: status));
        }
      }

      final derivedTitle = File(path).uri.pathSegments.isNotEmpty
          ? File(path).uri.pathSegments.last.replaceAll('.csv', '').trim()
          : 'Imported Program';
      final programTitle = _ensureUniqueTitle(ctrl, derivedTitle.isEmpty
          ? 'Imported Program'
          : derivedTitle);

      final program = Program(
        id: ctrl.uuid.v4(),
        title: programTitle,
        description:
            'Imported on ${DateTime.now().toIso8601String().split("T").first}',
        attendants: attendants,
        sessions: sessions,
      );

      await ctrl.addImportedProgram(program);

      Get.snackbar('Import Successful',
          'Program "$programTitle" imported with ${attendants.length} attendants and ${sessions.length} sessions.',
          duration: Duration(seconds: 12));
    } catch (e) {
      print('Error importing program CSV: $e');
      Get.snackbar('Import Error', 'Failed to import CSV: $e');
    }
  }

  /// Import a backup JSON file (export created by backupPrograms) and add contained programs to the app.
  static Future<void> importBackupJson() async {
    try {
      final ctrl = Get.find<ProgramController>();
      final fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select backup JSON',
      );
      if (fileResult == null || fileResult.files.isEmpty) return;

      String content;
      final file = fileResult.files.single;
      if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else {
        throw Exception('Unable to read selected file');
      }

      final data = json.decode(content);
      if (data == null || data['programs'] == null) {
        throw Exception('Invalid backup format');
      }

      int imported = 0;
      for (final p in (data['programs'] as List)) {
        try {
          final program = Program(
            id: p['id'] ?? ctrl.uuid.v4(),
            title: p['title'] ?? 'Imported Program',
            description: p['description'] ?? '',
            googleSheetUrl: p['googleSheetUrl'] ?? '',
            attendants: [],
            sessions: [],
          );

          // attendants
          final List attendants = (p['attendants'] ?? []) as List;
          for (final a in attendants) {
            program.attendants.add(Attendant(id: a['id'] ?? ctrl.uuid.v4(), name: a['name'] ?? ''));
          }

          // sessions
          final List sessions = (p['sessions'] ?? []) as List;
          for (final s in sessions) {
            final sess = Session(
              id: s['id'] ?? ctrl.uuid.v4(),
              title: s['title'] ?? 'Session',
              date: DateTime.tryParse(s['date'] ?? '') ?? DateTime.now(),
              isNewChapter: s['isNewChapter'] ?? false,
              attendance: [],
            );
            final List attList = (s['attendance'] ?? []) as List;
            for (final at in attList) {
              final statusStr = (at['status'] ?? 'Absent').toString();
              PresenceStatus status = PresenceStatus.Absent;
              if (statusStr.toLowerCase().contains('present')) status = PresenceStatus.Present;
              else if (statusStr.toLowerCase().contains('catch')) status = PresenceStatus.CatchUp;
              sess.attendance.add(Attendance(attendantId: at['attendantId'] ?? '', status: status));
            }
            program.sessions.add(sess);
          }

          await ctrl.addImportedProgram(program);
          imported++;
        } catch (inner) {
          print('Failed to import program entry: $inner');
        }
      }

      Get.snackbar('Import Successful', 'Imported $imported programs', duration: Duration(seconds: 8));
    } catch (e) {
      print('Error importing backup JSON: $e');
      Get.snackbar('Import Error', 'Failed to import backup: $e', duration: Duration(seconds: 8), backgroundColor: Colors.redAccent, colorText: Color(0xFFF9F9F9));
    }
  }

  // Method to pick directory using file picker
  static Future<String?> _pickDirectory() async {
    try {
      final String? selectedDirectory =
          await FilePicker.platform.getDirectoryPath();
      return selectedDirectory;
    } catch (e) {
      print('Error picking directory: $e');
      return null;
    }
  }

  // Export to Excel template from assets to user selected directory
  static Future<void> _exportToExcelDirectory(
      Program t, String directoryPath) async {
    try {
      // Load the Excel template from assets
      ByteData data = await rootBundle.load('assets/attend_me.xlsx');
      var bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excel = Excel.decodeBytes(bytes);

      // Check if there are any sheets in the Excel file
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in the Excel template file');
      }

      // Get the first sheet
      var sheetName = excel.tables.keys.first;
      var table = excel.tables[sheetName]!;

      // Clear existing data (keep header row)
      // Only remove rows if there are more than 1 row (header row)
      if (table.rows.length > 1) {
        table.rows.removeRange(1, table.rows.length);
      }

      // Add attendance data by directly setting cell values
      for (var i = 0; i < t.attendants.length; i++) {
        var tr = t.attendants[i];
        var rowIndex = 1 + i; // +1 because header row is at index 0

        // Set attendant name in first column (column 0)
        if (table.rows.length <= i) {
          // Add a new row if needed
          table.rows.add([]); // Add empty row
        }

        // Set attendant name
        var nameCell = table.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        nameCell.value = tr.name;

        // Set attendance marks for each session
        for (var j = 0; j < t.sessions.length; j++) {
          var session = t.sessions[j];
          final att = session.attendance.firstWhere((a) => a.attendantId == tr.id,
              orElse: () =>
                  Attendance(attendantId: tr.id, status: PresenceStatus.Absent));
          String mark = '';
          if (att.status == PresenceStatus.Present)
            mark = 'P';
          else if (att.status == PresenceStatus.Absent)
            mark = 'A';
          else
            mark = 'C';

          var markCell = table.cell(CellIndex.indexByColumnRow(
              columnIndex: j + 1, rowIndex: rowIndex));
          markCell.value = mark;
        }
      }

      // Save the modified Excel file
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        final fileName =
            '${t.title.replaceAll(RegExp(r'[^\w\s]+'), '_')}_attendance.xlsx';
        final file = File('$directoryPath/$fileName');
        await file.writeAsBytes(fileBytes);

        Get.snackbar(
          'Export Successful',
          'Attendance data saved to:\n${file.path}\n\nYou can open this Excel file directly.',
          duration: Duration(seconds: 15),
        );

        // Try to open the file
        try {
          if (await File(file.path).exists()) {
            final uri = Uri.file(file.path);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        } catch (launchError) {
          print('Could not launch file: $launchError');
        }
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      print('Error in _exportToExcelDirectory: $e');
      // Fallback to CSV if Excel export fails
      _exportAsCsvWithFallback(t);
    }
  }

  static Future<void> backupPrograms() async {
    try {
      final ctrl = Get.find<ProgramController>();
      if (ctrl.programs.isEmpty) {
        Get.snackbar('Backup', 'No programs to back up.');
        return;
      }

      final backupPayload = {
        'generatedAt': DateTime.now().toIso8601String(),
        'programs': ctrl.programs.map((program) {
          return {
            'id': program.id,
            'title': program.title,
            'description': program.description,
            'googleSheetUrl': program.googleSheetUrl,
            'attendants': program.attendants
                .map((attendant) => {
                      'id': attendant.id,
                      'name': attendant.name,
                    })
                .toList(),
            'sessions': program.sessions
                .map((session) => {
                      'id': session.id,
                      'title': session.title,
                      'date': session.date.toIso8601String(),
                      'isNewChapter': session.isNewChapter,
                      'attendance': session.attendance
                          .map((attendance) => {
                                'attendantId': attendance.attendantId,
                                'status': attendance.status.name,
                              })
                          .toList(),
                    })
                .toList(),
          };
        }).toList(),
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(backupPayload);
      final fileName =
          'attend_me_backup_${DateTime.now().toIso8601String().replaceAll(":", "-")}.json';
      final savedPath = await _saveTextFile(fileName, jsonContent);

      if (savedPath != null) {
        Get.snackbar('Backup Successful',
            'Backup saved to:\n$savedPath\n\nKeep this file safe for future restores.',
            duration: Duration(seconds: 12));
      } else {
        await Clipboard.setData(ClipboardData(text: jsonContent));
        Get.snackbar('Backup',
            'Could not write backup file. JSON copied to clipboard instead.',
            duration: Duration(seconds: 12));
      }
    } catch (e) {
      print('Error creating backup: $e');
      Get.snackbar('Backup Error', 'Failed to create backup: $e');
    }
  }

  /// Save backup JSON only to the provided directory. Returns the saved file path or null on failure.
  static Future<String?> backupProgramsToDirectory(String directoryPath, {String? fileName}) async {
    try {
      final ctrl = Get.find<ProgramController>();
      if (ctrl.programs.isEmpty) {
        throw Exception('No programs to back up.');
      }

      final backupPayload = {
        'generatedAt': DateTime.now().toIso8601String(),
        'programs': ctrl.programs.map((program) {
          return {
            'id': program.id,
            'title': program.title,
            'description': program.description,
            'googleSheetUrl': program.googleSheetUrl,
            'attendants': program.attendants
                .map((attendant) => {
                      'id': attendant.id,
                      'name': attendant.name,
                    })
                .toList(),
            'sessions': program.sessions
                .map((session) => {
                      'id': session.id,
                      'title': session.title,
                      'date': session.date.toIso8601String(),
                      'isNewChapter': session.isNewChapter,
                      'attendance': session.attendance
                          .map((attendance) => {
                                'attendantId': attendance.attendantId,
                                'status': attendance.status.name,
                              })
                          .toList(),
                    })
                .toList(),
          };
        }).toList(),
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(backupPayload);
      final generatedFileName = fileName ?? 'attend_me_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      final sanitizedName = generatedFileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

      final file = File('$directoryPath/$sanitizedName');
      await file.writeAsString(jsonContent);
      // On web we may want to trigger download; but this method is for IO directories only
      return file.path;
    } catch (e) {
      print('Error creating backup to directory: $e');
      return null;
    }
  }

  /// Trigger a download of the backup JSON for Web platforms.
  static Future<void> backupProgramsDownload({String? fileName}) async {
    final ctrl = Get.find<ProgramController>();
    if (ctrl.programs.isEmpty) {
      Get.snackbar('Backup', 'No programs to back up.');
      return;
    }
    final backupPayload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'programs': ctrl.programs.map((program) {
        return {
          'id': program.id,
          'title': program.title,
          'description': program.description,
          'googleSheetUrl': program.googleSheetUrl,
          'attendants': program.attendants
              .map((attendant) => {
                    'id': attendant.id,
                    'name': attendant.name,
                  })
              .toList(),
          'sessions': program.sessions
              .map((session) => {
                    'id': session.id,
                    'title': session.title,
                    'date': session.date.toIso8601String(),
                    'isNewChapter': session.isNewChapter,
                    'attendance': session.attendance
                        .map((attendance) => {
                              'attendantId': attendance.attendantId,
                              'status': attendance.status.name,
                            })
                        .toList(),
                  })
              .toList(),
        };
      }).toList(),
    };

    final jsonContent = const JsonEncoder.withIndent('  ').convert(backupPayload);
    final generatedFileName = fileName ?? 'attend_me_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
    final sanitizedName = generatedFileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    if (kIsWeb) {
      // Use the web helper to trigger download
      await triggerDownload(sanitizedName, jsonContent);
      Get.snackbar('Backup', 'Download started for $sanitizedName');
    } else {
      // Not web: save to temp and open dialog message
      final savedPath = await backupProgramsToDirectory(Directory.systemTemp.path, fileName: sanitizedName);
      if (savedPath != null) {
        Get.snackbar('Backup', 'Backup saved to $savedPath');
      } else {
        Get.snackbar('Backup', 'Failed to save backup to temp directory');
      }
    }
  }

  static Future<String?> _saveTextFile(String fileName, String contents) async {
    final sanitizedName =
        fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    final directoryLoaders = <Future<Directory?> Function()>[
      () async {
        try {
          return await getApplicationDocumentsDirectory();
        } on MissingPluginException catch (e) {
          print('MissingPluginException for documents dir: $e');
          return null;
        } catch (e) {
          print('Error getting documents dir: $e');
          return null;
        }
      },
      () async {
        try {
          return await getTemporaryDirectory();
        } on MissingPluginException catch (e) {
          print('MissingPluginException for temp dir: $e');
          return null;
        } catch (e) {
          print('Error getting temp dir: $e');
          return null;
        }
      },
    ];

    for (final getDirectory in directoryLoaders) {
      try {
        final dir = await getDirectory();
        if (dir == null) continue;
        final file = File('${dir.path}/$sanitizedName');
        await file.writeAsString(contents);
        return file.path;
      } on UnsupportedError catch (e) {
        print('UnsupportedError during file save: $e');
      } catch (e) {
        print('General error while saving file: $e');
      }
    }

    try {
      final manualDir = await _pickDirectory();
      if (manualDir != null) {
        final file = File('$manualDir/$sanitizedName');
        await file.writeAsString(contents);
        return file.path;
      }
    } catch (e) {
      print('Error saving file to picked directory: $e');
    }

    return null;
  }

  static _ParsedSessionHeader _parseSessionHeader(String raw, int index) {
    final trimmed = raw.trim();
    String title = trimmed.isEmpty ? 'Session ${index + 1}' : trimmed;
    DateTime date = DateTime.now().add(Duration(days: index));

    final match = RegExp(r'^(.*)\(([^)]+)\)$').firstMatch(trimmed);
    if (match != null) {
      final possibleTitle = match.group(1)?.trim();
      final possibleDate = match.group(2)?.trim();
      if (possibleTitle != null && possibleTitle.isNotEmpty) {
        title = possibleTitle;
      }
      if (possibleDate != null) {
        final parsed = DateTime.tryParse(possibleDate);
        if (parsed != null) {
          date = parsed;
        }
      }
    }

    return _ParsedSessionHeader(title, date);
  }

  static PresenceStatus _statusFromCell(String raw) {
    final value = raw.trim().toUpperCase();
    if (value.isEmpty) return PresenceStatus.Absent;
    if (value == 'P' || value == 'PRESENT') return PresenceStatus.Present;
    if (value == 'C' || value == 'CATCHUP' || value == 'CATCH UP') {
      return PresenceStatus.CatchUp;
    }
    return PresenceStatus.Absent;
  }

  static String _ensureUniqueTitle(
      ProgramController ctrl, String baseTitle) {
    var candidate = baseTitle;
    int suffix = 1;
    while (ctrl.programs.any((program) =>
        program.title.toLowerCase() == candidate.toLowerCase())) {
      candidate = '$baseTitle ($suffix)';
      suffix++;
    }
    return candidate;
  }

  // Extract CSV export to a separate method with comprehensive fallback
  static Future<void> _exportAsCsvWithFallback(Program t) async {
    try {
      List<List<String>> rows = [];
      List<String> header = ['Attendant'];
      for (var session in t.sessions) {
        header.add(
            '${session.title} (${session.date.toLocal().toIso8601String().split("T")[0]})');
      }
      rows.add(header);

      for (var tr in t.attendants) {
        List<String> row = [tr.name];
        for (var session in t.sessions) {
          final att = session.attendance.firstWhere((a) => a.attendantId == tr.id,
              orElse: () =>
                  Attendance(attendantId: tr.id, status: PresenceStatus.Absent));
          String mark = '';
          if (att.status == PresenceStatus.Present)
            mark = 'P';
          else if (att.status == PresenceStatus.Absent)
            mark = 'A';
          else
            mark = 'C';
          row.add(mark);
        }
        rows.add(row);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Try to save CSV file with multiple fallback options
      bool fileSaved = false;
      String filePath = '';

      // Try application documents directory
      try {
        final dir = await getApplicationDocumentsDirectory();
        final fileName =
            '${t.title.replaceAll(RegExp(r'[^\w\s]+'), '_')}_attendance.csv';
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(csv);
        filePath = file.path;
        fileSaved = true;
      } on MissingPluginException catch (e) {
        print(
            'MissingPluginException for getApplicationDocumentsDirectory: $e');
      } on UnsupportedError catch (e) {
        print('UnsupportedError for getApplicationDocumentsDirectory: $e');
      } catch (e) {
        print('Error getting application documents directory: $e');
      }

      // Try temporary directory if application documents failed
      if (!fileSaved) {
        try {
          final dir = await getTemporaryDirectory();
          final fileName =
              '${t.title.replaceAll(RegExp(r'[^\w\s]+'), '_')}_attendance.csv';
          final file = File('${dir.path}/$fileName');
          await file.writeAsString(csv);
          filePath = file.path;
          fileSaved = true;
        } on MissingPluginException catch (e) {
          print('MissingPluginException for getTemporaryDirectory: $e');
        } on UnsupportedError catch (e) {
          print('UnsupportedError for getTemporaryDirectory: $e');
        } catch (e) {
          print('Error getting temporary directory: $e');
        }
      }

      // Try current directory as last resort
      if (!fileSaved) {
        try {
          final dir = Directory.current;
          final fileName =
              '${t.title.replaceAll(RegExp(r'[^\w\s]+'), '_')}_attendance.csv';
          final file = File('${dir.path}/$fileName');
          await file.writeAsString(csv);
          filePath = file.path;
          fileSaved = true;
        } catch (e) {
          print('Error using current directory: $e');
        }
      }

      // If file was saved successfully, show success message
      if (fileSaved) {
        Get.snackbar(
          'Export Successful',
          'Attendance data saved as CSV to:\n$filePath\n\nYou can open this file in Excel or any spreadsheet application.',
          duration: Duration(seconds: 15),
        );

        // Try to open the file
        try {
          if (await File(filePath).exists()) {
            final uri = Uri.file(filePath);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        } catch (launchError) {
          print('Could not launch file: $launchError');
        }
      } else {
        // Final fallback: Copy CSV to clipboard and show in snackbar
        try {
          await Clipboard.setData(ClipboardData(text: csv));
          Get.snackbar(
            'Export Successful',
            'CSV data has been copied to clipboard!\n\nYou can paste it into a text editor or spreadsheet application.',
            duration: Duration(seconds: 10),
          );
        } catch (clipboardError) {
          print('Error copying to clipboard: $clipboardError');
          // Last resort: Show data in snackbar
          Get.snackbar(
            'Export Data',
            'CSV Data (copy manually):\n$csv',
            duration: Duration(seconds: 20),
          );
        }
      }
    } catch (csvError) {
      print('Error exporting program to CSV: $csvError');
      Get.snackbar('Export Error', 'Failed to export: $csvError');
    }
  }
}

class _ParsedSessionHeader {
  final String title;
  final DateTime date;

  _ParsedSessionHeader(this.title, this.date);
}
