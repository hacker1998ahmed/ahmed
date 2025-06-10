import '../core/shell_executor.dart';
import '../core/tool_manager.dart';

class HandshakeCracker {
  final ShellExecutor _shell = ShellExecutor.instance;
  bool _isCracking = false;

  Future<String?> crackHandshake(String handshakeFile, String wordlistFile) async {
    if (_isCracking) {
      throw Exception('Cracking is already in progress');
    }

    try {
      _isCracking = true;

      // Verify files exist
      final handshakeExists = await _shell.executeCommand('test -f $handshakeFile');
      final wordlistExists = await _shell.executeCommand('test -f $wordlistFile');

      if (handshakeExists.exitCode != 0) {
        throw Exception('Handshake file not found');
      }

      if (wordlistExists.exitCode != 0) {
        throw Exception('Wordlist file not found');
      }

      // Run aircrack-ng
      final result = await _shell.executeCommand(
        'aircrack-ng -w $wordlistFile $handshakeFile',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        
        // Parse output for password
        final keyMatch = RegExp(r'KEY FOUND! \[ (.+) \]').firstMatch(output);
        if (keyMatch != null) {
          return keyMatch.group(1);
        }
      }

      return null; // Password not found
    } catch (e) {
      throw Exception('Handshake cracking failed: $e');
    } finally {
      _isCracking = false;
    }
  }

  Stream<String> crackHandshakeStream(String handshakeFile, String wordlistFile) async* {
    if (_isCracking) {
      throw Exception('Cracking is already in progress');
    }

    try {
      _isCracking = true;

      yield 'Starting handshake cracking...';
      yield 'Handshake file: $handshakeFile';
      yield 'Wordlist file: $wordlistFile';

      // Stream aircrack-ng output
      await for (final line in _shell.executeStreamCommand(
        'aircrack-ng -w $wordlistFile $handshakeFile',
        requireRoot: true,
      )) {
        yield line;
        
        // Check if password found
        if (line.contains('KEY FOUND!')) {
          final keyMatch = RegExp(r'KEY FOUND! \[ (.+) \]').firstMatch(line);
          if (keyMatch != null) {
            yield 'Password found: ${keyMatch.group(1)}';
            break;
          }
        }
      }
    } catch (e) {
      yield 'Error: $e';
    } finally {
      _isCracking = false;
    }
  }

  Future<bool> validateHandshake(String handshakeFile) async {
    try {
      final result = await _shell.executeCommand(
        'aircrack-ng $handshakeFile',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        return output.contains('handshake') || output.contains('WPA');
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAvailableWordlists() async {
    try {
      final wordlistsDir = ToolManager.instance.wordlistsPath;
      final result = await _shell.executeCommand('ls $wordlistsDir/*.txt');

      if (result.exitCode == 0) {
        return result.stdout.toString().split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  bool get isCracking => _isCracking;
}