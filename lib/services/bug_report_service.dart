import 'package:uuid/uuid.dart';
import '../models/bug_report_model.dart';
import 'database_service.dart';

class BugReportService {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<void> submitBugReport(BugReportModel report) async {
    final db = await _db.database;
    final map = report.toMap();
    map['id'] ??= _uuid.v4();
    await db.insert('bug_reports', map);
    _db.notify('bug_reports');
  }

  Stream<List<BugReportModel>> getUserBugReports(String userId) async* {
    await for (final _ in _db.watchTable('bug_reports')) {
      final db = await _db.database;
      final rows = await db.query(
        'bug_reports',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );
      yield rows.map(BugReportModel.fromMap).toList();
    }
  }
}
