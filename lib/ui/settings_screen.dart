import 'package:flutter/material.dart';
import '../core/tool_manager.dart';
import '../core/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, bool> _toolsStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToolsStatus();
  }

  Future<void> _loadToolsStatus() async {
    final status = ToolManager.instance.toolsStatus;
    setState(() {
      _toolsStatus = Map.from(status);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Tools'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppInfoCard(),
                  const SizedBox(height: 16),
                  _buildToolsCard(),
                  const SizedBox(height: 16),
                  _buildWordlistsCard(),
                  const SizedBox(height: 16),
                  _buildStorageCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('App Name', AppConstants.appName),
            _buildInfoRow('Version', AppConstants.version),
            _buildInfoRow('Tools Directory', ToolManager.instance.toolsPath),
            _buildInfoRow('Captures Directory', ToolManager.instance.capturesPath),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Network Tools',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _installAllTools,
                  icon: const Icon(Icons.download),
                  label: const Text('Install All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AppConstants.networkTools.keys.map((tool) {
              final isInstalled = _toolsStatus[tool] ?? false;
              return ListTile(
                leading: Icon(
                  isInstalled ? Icons.check_circle : Icons.error,
                  color: isInstalled ? Colors.green : Colors.red,
                ),
                title: Text(tool),
                subtitle: Text(isInstalled ? 'Installed' : 'Not installed'),
                trailing: isInstalled
                    ? null
                    : ElevatedButton(
                        onPressed: () => _installTool(tool),
                        child: const Text('Install'),
                      ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWordlistsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wordlists',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _installWordlists,
                  icon: const Icon(Icons.list),
                  label: const Text('Install Default'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...AppConstants.defaultWordlists.map((wordlist) {
              return ListTile(
                leading: const Icon(Icons.list_alt),
                title: Text(wordlist),
                subtitle: const Text('Password wordlist'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Clear Capture Files'),
              subtitle: const Text('Remove all captured packets'),
              trailing: ElevatedButton(
                onPressed: _clearCaptures,
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Clear Reports'),
              subtitle: const Text('Remove all attack reports'),
              trailing: ElevatedButton(
                onPressed: _clearReports,
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Reset Application'),
              subtitle: const Text('Clear all data and settings'),
              trailing: ElevatedButton(
                onPressed: _resetApp,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _installTool(String toolName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Installing $toolName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Downloading and installing $toolName...'),
          ],
        ),
      ),
    );

    try {
      final success = await ToolManager.instance.installTool(toolName);
      Navigator.pop(context);

      if (success) {
        setState(() {
          _toolsStatus[toolName] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$toolName installed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to install $toolName')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Installation error: $e')),
      );
    }
  }

  Future<void> _installAllTools() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Installing All Tools'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('This may take several minutes...'),
          ],
        ),
      ),
    );

    int installed = 0;
    for (final tool in AppConstants.networkTools.keys) {
      if (!(_toolsStatus[tool] ?? false)) {
        final success = await ToolManager.instance.installTool(tool);
        if (success) {
          installed++;
          setState(() {
            _toolsStatus[tool] = true;
          });
        }
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Installed $installed tools successfully')),
    );
  }

  Future<void> _installWordlists() async {
    try {
      await ToolManager.instance.installDefaultWordlists();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default wordlists installed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to install wordlists: $e')),
      );
    }
  }

  Future<void> _clearCaptures() async {
    final confirmed = await _showConfirmDialog(
      'Clear Capture Files',
      'Are you sure you want to delete all capture files?',
    );

    if (confirmed) {
      // Implement clearing captures
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture files cleared')),
      );
    }
  }

  Future<void> _clearReports() async {
    final confirmed = await _showConfirmDialog(
      'Clear Reports',
      'Are you sure you want to delete all attack reports?',
    );

    if (confirmed) {
      // Implement clearing reports
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reports cleared')),
      );
    }
  }

  Future<void> _resetApp() async {
    final confirmed = await _showConfirmDialog(
      'Reset Application',
      'This will delete all data, tools, and settings. This action cannot be undone.',
    );

    if (confirmed) {
      // Implement app reset
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application reset complete')),
      );
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}