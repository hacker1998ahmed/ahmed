import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../modules/packet_analyzer.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final PacketAnalyzer _analyzer = PacketAnalyzer();
  List<PacketInfo> _packets = [];
  String? _selectedFile;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packet Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _selectCaptureFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture File Analysis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFile != null)
                    Text('File: ${_selectedFile!.split('/').last}')
                  else
                    const Text('No file selected'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectCaptureFile,
                          icon: const Icon(Icons.file_open),
                          label: const Text('Select Capture File'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _selectedFile != null && !_isAnalyzing
                            ? _analyzeFile
                            : null,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.analytics),
                        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_packets.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Packets: ${_packets.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _buildFilterChips(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _packets.length,
                itemBuilder: (context, index) {
                  final packet = _packets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getProtocolColor(packet.protocol),
                        child: Text(
                          packet.protocol.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text('${packet.source} → ${packet.destination}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Protocol: ${packet.protocol}'),
                          Text('Size: ${packet.size} bytes | Time: ${packet.timestamp}'),
                          if (packet.info.isNotEmpty) Text('Info: ${packet.info}'),
                        ],
                      ),
                      onTap: () => _showPacketDetails(packet),
                    ),
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Text('Select and analyze a capture file to view packets'),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips() {
    final protocols = _packets.map((p) => p.protocol).toSet().toList();
    
    return Wrap(
      spacing: 4,
      children: protocols.map((protocol) {
        return FilterChip(
          label: Text(protocol),
          onSelected: (selected) {
            // Implement filtering
          },
        );
      }).toList(),
    );
  }
  
  Future<void> _selectCaptureFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cap', 'pcap', 'pcapng'],
      );
      
      if (result != null) {
        setState(() {
          _selectedFile = result.files.single.path;
          _packets.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select file: $e')),
      );
    }
  }
  
  Future<void> _analyzeFile() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final packets = await _analyzer.analyzeCapture(_selectedFile!);
      setState(() {
        _packets = packets;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
  
  void _showPacketDetails(PacketInfo packet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Packet Details - ${packet.protocol}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Source', packet.source),
                _buildDetailRow('Destination', packet.destination),
                _buildDetailRow('Protocol', packet.protocol),
                _buildDetailRow('Size', '${packet.size} bytes'),
                _buildDetailRow('Timestamp', packet.timestamp),
                if (packet.info.isNotEmpty) _buildDetailRow('Info', packet.info),
                const SizedBox(height: 16),
                const Text('Raw Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    packet.rawData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
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
  
  Color _getProtocolColor(String protocol) {
    switch (protocol.toUpperCase()) {
      case 'TCP':
        return Colors.blue;
      case 'UDP':
        return Colors.green;
      case 'ICMP':
        return Colors.orange;
      case 'ARP':
        return Colors.purple;
      case 'DNS':
        return Colors.teal;
      case 'HTTP':
        return Colors.red;
      case 'HTTPS':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}