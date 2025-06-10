import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../modules/report_manager.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportManager _reportManager = ReportManager();
  List<AttackReport> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _reportManager.getAllReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attack Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_all',
                child: Text('Export All Reports'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All Reports'),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No reports available'),
                      Text('Attack reports will appear here after running tests'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryCard(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(report.status),
                                child: Icon(
                                  _getStatusIcon(report.status),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(report.attackType),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Target: ${report.target}'),
                                  Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(report.timestamp)}'),
                                  Text('Duration: ${report.duration}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Text('View Details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'export',
                                    child: Text('Export Report'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) => _handleReportAction(report, value),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildSummaryCard() {
    final totalReports = _reports.length;
    final successfulAttacks = _reports.where((r) => r.status == 'success').length;
    final failedAttacks = _reports.where((r) => r.status == 'failed').length;
    final ongoingAttacks = _reports.where((r) => r.status == 'ongoing').length;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total', totalReports, Colors.blue),
                _buildSummaryItem('Success', successfulAttacks, Colors.green),
                _buildSummaryItem('Failed', failedAttacks, Colors.red),
                _buildSummaryItem('Ongoing', ongoingAttacks, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_all':
        _exportAllReports();
        break;
      case 'clear_all':
        _clearAllReports();
        break;
    }
  }
  
  void _handleReportAction(AttackReport report, String action) {
    switch (action) {
      case 'view':
        _viewReportDetails(report);
        break;
      case 'export':
        _exportReport(report);
        break;
      case 'delete':
        _deleteReport(report);
        break;
    }
  }
  
  void _viewReportDetails(AttackReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${report.attackType} Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Attack Type', report.attackType),
                _buildDetailRow('Target', report.target),
                _buildDetailRow('Status', report.status.toUpperCase()),
                _buildDetailRow('Start Time', DateFormat('MMM dd, yyyy HH:mm:ss').format(report.timestamp)),
                _buildDetailRow('Duration', report.duration),
                const SizedBox(height: 16),
                const Text('Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    report.results.isEmpty ? 'No results available' : report.results,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                if (report.logs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      report.logs,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  Future<void> _exportReport(AttackReport report) async {
    try {
      await _reportManager.exportReport(report);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
  
  Future<void> _exportAllReports() async {
    try {
      await _reportManager.exportAllReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All reports exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
  
  Future<void> _deleteReport(AttackReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _reportManager.deleteReport(report.id);
        await _loadReports();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }
  
  Future<void> _clearAllReports() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Reports'),
        content: const Text('Are you sure you want to delete all reports? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _reportManager.clearAllReports();
        await _loadReports();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All reports cleared successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clear failed: $e')),
        );
      }
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'ongoing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check;
      case 'failed':
        return Icons.close;
      case 'ongoing':
        return Icons.hourglass_empty;
      default:
        return Icons.help;
    }
  }
}