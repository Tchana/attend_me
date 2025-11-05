import 'package:attend_me/models/attendance.dart';
import 'package:attend_me/models/training.dart';
import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excel/excel.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../controllers/training_controller.dart';

class CsvService {
  static Future<void> exportTrainingToCsv(String trainingId) async {
    try {
      final ctrl = Get.find<TrainingController>();

      // Check if training exists
      if (ctrl.trainings.isEmpty) {
        throw Exception('No trainings found');
      }

      final t = ctrl.trainings.firstWhere(
        (tr) => tr.id == trainingId,
        orElse: () => throw Exception('Training with ID $trainingId not found'),
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
      print('Error exporting training to Excel: $e');
      Get.snackbar('Export Error', 'Failed to export: $e');
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
      Training t, String directoryPath) async {
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
      for (var i = 0; i < t.trainees.length; i++) {
        var tr = t.trainees[i];
        var rowIndex = 1 + i; // +1 because header row is at index 0

        // Set trainee name in first column (column 0)
        if (table.rows.length <= i) {
          // Add a new row if needed
          table.rows.add([]); // Add empty row
        }

        // Set trainee name
        var nameCell = table.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
        nameCell.value = tr.name;

        // Set attendance marks for each lesson
        for (var j = 0; j < t.lessons.length; j++) {
          var lesson = t.lessons[j];
          final att = lesson.attendance.firstWhere((a) => a.traineeId == tr.id,
              orElse: () =>
                  Attendance(traineeId: tr.id, status: PresenceStatus.Absent));
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

  // Export as CSV (original functionality)
  static Future<void> _exportAsCsv(Training t) async {
    try {
      List<List<String>> rows = [];
      List<String> header = ['Trainee'];
      for (var lesson in t.lessons) {
        header.add(
            '${lesson.title} (${lesson.date.toLocal().toIso8601String().split("T")[0]})');
      }
      rows.add(header);

      for (var tr in t.trainees) {
        List<String> row = [tr.name];
        for (var lesson in t.lessons) {
          final att = lesson.attendance.firstWhere((a) => a.traineeId == tr.id,
              orElse: () =>
                  Attendance(traineeId: tr.id, status: PresenceStatus.Absent));
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

      // Copy CSV to clipboard
      await Clipboard.setData(ClipboardData(text: csv));

      Get.snackbar(
        'Export Successful',
        'CSV data has been copied to clipboard!\n\nYou can paste it into a text editor or spreadsheet application.',
        duration: Duration(seconds: 10),
      );
    } catch (e) {
      print('Error exporting training to CSV: $e');

      Get.snackbar('Export Error', 'Failed to export CSV: $e');
    }
  }

  // Extract CSV export to a separate method with comprehensive fallback
  static Future<void> _exportAsCsvWithFallback(Training t) async {
    try {
      List<List<String>> rows = [];
      List<String> header = ['Trainee'];
      for (var lesson in t.lessons) {
        header.add(
            '${lesson.title} (${lesson.date.toLocal().toIso8601String().split("T")[0]})');
      }
      rows.add(header);

      for (var tr in t.trainees) {
        List<String> row = [tr.name];
        for (var lesson in t.lessons) {
          final att = lesson.attendance.firstWhere((a) => a.traineeId == tr.id,
              orElse: () =>
                  Attendance(traineeId: tr.id, status: PresenceStatus.Absent));
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
      print('Error exporting training to CSV: $csvError');
      Get.snackbar('Export Error', 'Failed to export: $csvError');
    }
  }
}
