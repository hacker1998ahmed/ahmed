import 'dart:io';
import 'dart:convert';
import '../core/tool_manager.dart';

class AttackReport {
  final String id;
  final String attackType;
  final String target;
  final DateTime timestamp;
  final String status;
  final String duration;
  final String results;
  final String logs;

  AttackReport({
    required this.id,
    required this.attackType,
    required this.target,
    required this.timestamp,
    required this.status,
    required this.duration,
    this.results = '',
    this.logs = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attackType': attackType,
      'target': target,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'duration': duration,
      'results': results,
      'logs': logs,
    };
  }

  factory AttackReport.fromJson(Map<String, dynamic> json) {
    return AttackReport(
      id: json['id'],
      attackType: json['attackType'],
      target: json['target'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
      duration: json['duration'],
      results: json['results'] ?? '',
      logs: json['logs'] ?? '',
    );
  }
}

class ReportManager {
  late File _reportsFile;

  ReportManager() {
    _reportsFile = File('${ToolManager.instance.reportsPath}/reports.json');
  }

  Future<void> saveReport(AttackReport report) async {
    try {
      final reports = await getAllReports();
      reports.add(report);
      
      final jsonData = reports.map((r) => r.toJson()).toList();
      await _reportsFile.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      throw Exception('Failed to save report: $e');
    }
  }

  Future<List<AttackReport>> getAllReports() async {
    try {
      if (!await _reportsFile.exists()) {
        return [];
      }

      final content = await _reportsFile.readAsString();
      final List<dynamic> jsonData = jsonDecode(content);
      
      return jsonData.map((json) => AttackReport.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      final reports = await getAllReports();
      reports.removeWhere((report) => report.id == reportId);
      
      final jsonData = reports.map((r) => r.toJson()).toList();
      await _reportsFile.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  Future<void> clearAllReports() async {
    try {
      await _reportsFile.writeAsString('[]');
    } catch (e) {
      throw Exception('Failed to clear reports: $e');
    }
  }

  Future<void> exportReport(AttackReport report) async {
    try {
      final exportFile = File('${ToolManager.instance.reportsPath}/report_${report.id}.txt');
      
      final content = '''
WiMax Pentest Tool - Attack Report
==================================

Report ID: ${report.id}
Attack Type: ${report.attackType}
Target: ${report.target}
Timestamp: ${report.timestamp}
Status: ${report.status}
Duration: ${report.duration}

Results:
--------
${report.results}

Logs:
-----
${report.logs}
''';

      await exportFile.writeAsString(content);
    } catch (e) {
      throw Exception('Failed to export report: $e');
    }
  }

  Future<void> exportAllReports() async {
    try {
      final reports = await getAllReports();
      final exportFile = File('${ToolManager.instance.reportsPath}/all_reports_${DateTime.now().millisecondsSinceEpoch}.json');
      
      final jsonData = reports.map((r) => r.toJson()).toList();
      await exportFile.writeAsString(jsonEncode(jsonData));
    } catch (e) {
      throw Exception('Failed to export all reports: $e');
    }
  }

  Future<AttackReport> createReport({
    required String attackType,
    required String target,
    required String status,
    required String duration,
    String results = '',
    String logs = '',
  }) async {
    final report = AttackReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      attackType: attackType,
      target: target,
      timestamp: DateTime.now(),
      status: status,
      duration: duration,
      results: results,
      logs: logs,
    );

    await saveReport(report);
    return report;
  }
}