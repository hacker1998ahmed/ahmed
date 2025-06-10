import 'package:flutter/material.dart';
import '../../modules/wifi_scanner.dart';
import '../../modules/handshake_cracker.dart';
import '../../modules/wps_attack.dart';

class WiFiScreen extends StatefulWidget {
  const WiFiScreen({super.key});

  @override
  State<WiFiScreen> createState() => _WiFiScreenState();
}

class _WiFiScreenState extends State<WiFiScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  final WiFiScanner _wifiScanner = WiFiScanner();
  final HandshakeCracker _handshakeCracker = HandshakeCracker();
  final WpsAttack _wpsAttack = WpsAttack();
  
  List<WiFiNetwork> _networks = [];
  bool _isScanning = false;
  bool _isMonitorMode = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Attacks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Networks', icon: Icon(Icons.wifi)),
            Tab(text: 'WPA Crack', icon: Icon(Icons.lock_open)),
            Tab(text: 'WPS Attack', icon: Icon(Icons.security)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNetworksTab(),
          _buildWpaCrackTab(),
          _buildWpsAttackTab(),
        ],
      ),
    );
  }
  
  Widget _buildNetworksTab() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanNetworks,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isScanning ? 'Scanning...' : 'Scan Networks'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _toggleMonitorMode,
                      icon: Icon(_isMonitorMode ? Icons.monitor : Icons.monitor_outlined),
                      label: Text(_isMonitorMode ? 'Stop Monitor' : 'Monitor Mode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMonitorMode ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Networks Found: ${_networks.length}'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _networks.isEmpty
              ? const Center(child: Text('No networks found. Start scanning to discover WiFi networks.'))
              : ListView.builder(
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    final network = _networks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          _getSecurityIcon(network.security),
                          color: _getSecurityColor(network.security),
                        ),
                        title: Text(network.ssid.isEmpty ? 'Hidden Network' : network.ssid),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BSSID: ${network.bssid}'),
                            Text('Channel: ${network.channel} | Signal: ${network.signal}dBm'),
                            Text('Security: ${network.security}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'handshake',
                              child: Text('Capture Handshake'),
                            ),
                            const PopupMenuItem(
                              value: 'wps',
                              child: Text('WPS Attack'),
                            ),
                            const PopupMenuItem(
                              value: 'deauth',
                              child: Text('Deauth Attack'),
                            ),
                          ],
                          onSelected: (value) => _handleNetworkAction(network, value),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildWpaCrackTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WPA/WPA2 Handshake Cracking',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _selectHandshakeFile(),
                    icon: const Icon(Icons.file_open),
                    label: const Text('Select Handshake File'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _selectWordlist(),
                    icon: const Icon(Icons.list),
                    label: const Text('Select Wordlist'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startCracking(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Cracking'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWpsAttackTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WPS PIN Attack',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Attack WPS-enabled networks by brute-forcing the PIN.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Target BSSID',
                      hintText: '00:11:22:33:44:55',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startWpsAttack(),
                      icon: const Icon(Icons.security),
                      label: const Text('Start WPS Attack'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _scanNetworks() async {
    setState(() {
      _isScanning = true;
      _networks.clear();
    });
    
    try {
      final networks = await _wifiScanner.scanNetworks();
      setState(() {
        _networks = networks;
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
  
  Future<void> _toggleMonitorMode() async {
    try {
      if (_isMonitorMode) {
        await _wifiScanner.disableMonitorMode();
      } else {
        await _wifiScanner.enableMonitorMode();
      }
      setState(() {
        _isMonitorMode = !_isMonitorMode;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle monitor mode: $e')),
      );
    }
  }
  
  void _handleNetworkAction(WiFiNetwork network, String action) {
    switch (action) {
      case 'handshake':
        _captureHandshake(network);
        break;
      case 'wps':
        _attackWps(network);
        break;
      case 'deauth':
        _deauthAttack(network);
        break;
    }
  }
  
  Future<void> _captureHandshake(WiFiNetwork network) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Capture Handshake - ${network.ssid}'),
        content: const Text('Starting handshake capture...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _attackWps(WiFiNetwork network) async {
    // Implement WPS attack
  }
  
  Future<void> _deauthAttack(WiFiNetwork network) async {
    // Implement deauth attack
  }
  
  Future<void> _selectHandshakeFile() async {
    // Implement file picker for handshake files
  }
  
  Future<void> _selectWordlist() async {
    // Implement wordlist selection
  }
  
  Future<void> _startCracking() async {
    // Implement handshake cracking
  }
  
  Future<void> _startWpsAttack() async {
    // Implement WPS PIN attack
  }
  
  IconData _getSecurityIcon(String security) {
    if (security.contains('WPA')) return Icons.lock;
    if (security.contains('WEP')) return Icons.lock_outline;
    return Icons.lock_open;
  }
  
  Color _getSecurityColor(String security) {
    if (security.contains('WPA')) return Colors.red;
    if (security.contains('WEP')) return Colors.orange;
    return Colors.green;
  }
}