import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../core/constants.dart';
import '../core/shell_executor.dart';
import '../core/tool_manager.dart';
import 'modules/recon_screen.dart';
import 'modules/exploit_screen.dart';
import 'modules/wifi_screen.dart';
import 'modules/analysis_screen.dart';
import 'modules/reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRooted = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _checkSystemStatus();
  }
  
  Future<void> _checkSystemStatus() async {
    final isRooted = await ShellExecutor.instance.checkRootAccess();
    setState(() {
      _isRooted = isRooted;
      _isLoading = false;
    });
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.red),
            const SizedBox(width: 8),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'WiMax Pentest',
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              isRepeatingAnimation: false,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildModulesGrid(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isRooted ? Icons.check_circle : Icons.error,
                  color: _isRooted ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Root Access', _isRooted),
            _buildStatusRow('Network Tools', true),
            _buildStatusRow('Permissions', true),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status ? 'OK' : 'FAIL',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModulesGrid() {
    final modules = [
      {
        'title': 'Network Recon',
        'subtitle': 'Discover devices and services',
        'icon': Icons.radar,
        'color': Colors.blue,
        'screen': const ReconScreen(),
      },
      {
        'title': 'Exploitation',
        'subtitle': 'MITM, ARP Spoofing, DNS',
        'icon': Icons.bug_report,
        'color': Colors.orange,
        'screen': const ExploitScreen(),
      },
      {
        'title': 'WiFi Attacks',
        'subtitle': 'WPA/WPS cracking',
        'icon': Icons.wifi,
        'color': Colors.purple,
        'screen': const WiFiScreen(),
      },
      {
        'title': 'Analysis',
        'subtitle': 'Packet analysis & forensics',
        'icon': Icons.analytics,
        'color': Colors.green,
        'screen': const AnalysisScreen(),
      },
      {
        'title': 'Reports',
        'subtitle': 'View attack logs & results',
        'icon': Icons.description,
        'color': Colors.teal,
        'screen': const ReportsScreen(),
      },
      {
        'title': 'Tools',
        'subtitle': 'Manage installed tools',
        'icon': Icons.build,
        'color': Colors.red,
        'screen': const SettingsScreen(),
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleCard(module);
      },
    );
  }
  
  Widget _buildModuleCard(Map<String, dynamic> module) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => module['screen']),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                module['icon'],
                size: 48,
                color: module['color'],
              ),
              const SizedBox(height: 12),
              Text(
                module['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                module['subtitle'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}