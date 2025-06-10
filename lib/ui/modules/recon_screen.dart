import 'package:flutter/material.dart';
import '../../core/shell_executor.dart';
import '../../modules/network_scanner.dart';

class ReconScreen extends StatefulWidget {
  const ReconScreen({super.key});

  @override
  State<ReconScreen> createState() => _ReconScreenState();
}

class _ReconScreenState extends State<ReconScreen> {
  final NetworkScanner _scanner = NetworkScanner();
  List<NetworkDevice> _devices = [];
  bool _isScanning = false;
  String _networkInterface = 'wlan0';
  
  @override
  void initState() {
    super.initState();
    _getNetworkInterface();
  }
  
  Future<void> _getNetworkInterface() async {
    final interface = await ShellExecutor.instance.getNetworkInterface();
    setState(() {
      _networkInterface = interface;
    });
  }
  
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });
    
    try {
      final devices = await _scanner.scanNetwork(_networkInterface);
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Reconnaissance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
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
                    'Network Interface: $_networkInterface',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Devices Found: ${_devices.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isScanning ? 'Scanning...' : 'Start Network Scan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(
                    child: Text('No devices found. Start a scan to discover network devices.'),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: device.isOnline ? Colors.green : Colors.red,
                            child: Icon(
                              device.isOnline ? Icons.computer : Icons.computer_outlined,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(device.hostname.isEmpty ? 'Unknown Device' : device.hostname),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('IP: ${device.ipAddress}'),
                              Text('MAC: ${device.macAddress}'),
                              if (device.vendor.isNotEmpty) Text('Vendor: ${device.vendor}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'ping',
                                child: Text('Ping Test'),
                              ),
                              const PopupMenuItem(
                                value: 'portscan',
                                child: Text('Port Scan'),
                              ),
                              const PopupMenuItem(
                                value: 'target',
                                child: Text('Set as Target'),
                              ),
                            ],
                            onSelected: (value) => _handleDeviceAction(device, value),
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
  
  void _handleDeviceAction(NetworkDevice device, String action) {
    switch (action) {
      case 'ping':
        _pingDevice(device);
        break;
      case 'portscan':
        _portScanDevice(device);
        break;
      case 'target':
        _setAsTarget(device);
        break;
    }
  }
  
  Future<void> _pingDevice(NetworkDevice device) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ping ${device.ipAddress}'),
        content: const Text('Pinging device...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _portScanDevice(NetworkDevice device) async {
    // Implement port scanning
  }
  
  void _setAsTarget(NetworkDevice device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${device.ipAddress} set as target')),
    );
  }
}