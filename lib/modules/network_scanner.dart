import '../core/shell_executor.dart';

class NetworkDevice {
  final String ipAddress;
  final String macAddress;
  final String hostname;
  final String vendor;
  final bool isOnline;
  final List<int> openPorts;

  NetworkDevice({
    required this.ipAddress,
    required this.macAddress,
    this.hostname = '',
    this.vendor = '',
    this.isOnline = false,
    this.openPorts = const [],
  });
}

class NetworkScanner {
  final ShellExecutor _shell = ShellExecutor.instance;

  Future<List<NetworkDevice>> scanNetwork(String interface) async {
    final devices = <NetworkDevice>[];
    
    try {
      // Get network range
      final networkRange = await _getNetworkRange(interface);
      
      // Perform ARP scan
      final arpResult = await _shell.executeCommand(
        'nmap -sn $networkRange',
        requireRoot: true,
      );
      
      if (arpResult.exitCode == 0) {
        final lines = arpResult.stdout.toString().split('\n');
        
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          
          if (line.startsWith('Nmap scan report for')) {
            final ipMatch = RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(line);
            if (ipMatch != null) {
              final ip = ipMatch.group(1)!;
              
              // Get MAC address
              final macResult = await _shell.executeCommand('arp -n $ip');
              String mac = '';
              if (macResult.exitCode == 0) {
                final macMatch = RegExp(r'([0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2})')
                    .firstMatch(macResult.stdout.toString());
                if (macMatch != null) {
                  mac = macMatch.group(1)!;
                }
              }
              
              // Get hostname
              final hostnameResult = await _shell.executeCommand('nslookup $ip');
              String hostname = '';
              if (hostnameResult.exitCode == 0) {
                final hostnameMatch = RegExp(r'name = (.+)\.').firstMatch(hostnameResult.stdout.toString());
                if (hostnameMatch != null) {
                  hostname = hostnameMatch.group(1)!;
                }
              }
              
              devices.add(NetworkDevice(
                ipAddress: ip,
                macAddress: mac,
                hostname: hostname,
                vendor: _getVendorFromMac(mac),
                isOnline: true,
              ));
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Network scan failed: $e');
    }
    
    return devices;
  }

  Future<String> _getNetworkRange(String interface) async {
    final result = await _shell.executeCommand('ip route show dev $interface');
    
    if (result.exitCode == 0) {
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.contains('/')) {
          final match = RegExp(r'(\d+\.\d+\.\d+\.\d+/\d+)').firstMatch(line);
          if (match != null) {
            return match.group(1)!;
          }
        }
      }
    }
    
    return '192.168.1.0/24'; // fallback
  }

  String _getVendorFromMac(String mac) {
    if (mac.isEmpty) return '';
    
    final oui = mac.substring(0, 8).toUpperCase();
    
    // Basic OUI to vendor mapping
    final vendors = {
      '00:50:56': 'VMware',
      '08:00:27': 'VirtualBox',
      '00:0C:29': 'VMware',
      '00:1B:21': 'Intel',
      '00:23:24': 'Apple',
      '28:CF:E9': 'Apple',
      'B8:27:EB': 'Raspberry Pi',
      'DC:A6:32': 'Raspberry Pi',
    };
    
    return vendors[oui] ?? 'Unknown';
  }

  Future<List<int>> scanPorts(String ipAddress, List<int> ports) async {
    final openPorts = <int>[];
    
    try {
      final portsStr = ports.join(',');
      final result = await _shell.executeCommand(
        'nmap -p $portsStr $ipAddress',
        requireRoot: true,
      );
      
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains('/tcp') && line.contains('open')) {
            final portMatch = RegExp(r'(\d+)/tcp').firstMatch(line);
            if (portMatch != null) {
              openPorts.add(int.parse(portMatch.group(1)!));
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Port scan failed: $e');
    }
    
    return openPorts;
  }
}