import 'package:attend_me/models/attendance.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import '../models/training.dart';

class SheetsService {
  // Note: For Google Sign-In to work properly, you need to:
  // 1. Configure SHA-1 fingerprint in your Android app
  // 2. Set up OAuth client in Google Cloud Console
  // 3. Enable Google Sheets API
  // 4. Add google-services.json to android/app/
  // See GOOGLE_SIGN_IN_SETUP.md for detailed instructions
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [sheets.SheetsApi.spreadsheetsScope],
  );

  // Call to sync a training to the provided googleSheetUrl
  // This is a simple example that overwrites the sheet with a table:
  // Trainee | Lesson1 (date) | Lesson2 ...
  static Future<void> syncTrainingToSheet(Training t) async {
    if (t.googleSheetUrl.isEmpty) return;

    try {
      final account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (account == null) return;

      final authHeaders = await account.authHeaders;
      final client = GoogleHttpClient(authHeaders);
      final api = sheets.SheetsApi(client);

      // extract spreadsheetId from url
      final spreadsheetId = _spreadsheetIdFromUrl(t.googleSheetUrl);
      if (spreadsheetId == null) return;

      // Build header row: Trainee, then each lesson date/title
      List<List<Object?>> values = [];
      List<Object?> header = ['Trainee'];
      for (var lesson in t.lessons) {
        header.add('${lesson.title} (${lesson.date.toIso8601String().split("T").first})');
      }
      values.add(header);

      // Each trainee row
      for (var trainee in t.trainees) {
        List<Object?> row = [trainee.name];
        for (var lesson in t.lessons) {
          final a = lesson.attendance.firstWhere((att) => att.traineeId == trainee.id, orElse: () => Attendance(traineeId: '', status: PresenceStatus.Absent));
          String mark = '';
          if (a.traineeId.isEmpty) mark = '';
          else if (a.status == PresenceStatus.Present) mark = 'P';
          else if (a.status == PresenceStatus.Absent) mark = 'A';
          else if (a.status == PresenceStatus.CatchUp) mark = 'C';
          row.add(mark);
        }
        values.add(row);
      }

      final valueRange = sheets.ValueRange(values: values);
      await api.spreadsheets.values.update(valueRange, spreadsheetId, 'Sheet1!A1',
          valueInputOption: 'RAW');

    } catch (e) {
      print('Sheets sync error: $e');
    }
  }

  static String? _spreadsheetIdFromUrl(String url) {
    try {
      final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
      final match = regex.firstMatch(url);
      if (match != null) return match.group(1);
    } catch (_) {}
    return null;
  }
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
