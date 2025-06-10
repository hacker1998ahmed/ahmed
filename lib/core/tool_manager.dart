import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'constants.dart';
import 'shell_executor.dart';

class ToolManager {
  static final ToolManager _instance = ToolManager._internal();
  factory ToolManager() => _instance;
  ToolManager._internal();
  
  static ToolManager get instance => _instance;
  
  late Directory _toolsDirectory;
  late Directory _wordlistsDirectory;
  late Directory _capturesDirectory;
  late Directory _reportsDirectory;
  
  Map<String, bool> _toolsStatus = {};
  
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    
    _toolsDirectory = Directory('${appDir.path}/tools');
    _wordlistsDirectory = Directory('${appDir.path}/wordlists');
    _capturesDirectory = Directory('${appDir.path}/captures');
    _reportsDirectory = Directory('${appDir.path}/reports');
    
    await _createDirectories();
    await _checkInstalledTools();
  }
  
  Future<void> _createDirectories() async {
    for (final dir in [_toolsDirectory, _wordlistsDirectory, _capturesDirectory, _reportsDirectory]) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }
  
  Future<void> _checkInstalledTools() async {
    for (final tool in AppConstants.networkTools.keys) {
      _toolsStatus[tool] = await _isToolInstalled(tool);
    }
  }
  
  Future<bool> _isToolInstalled(String toolName) async {
    final toolPath = '${_toolsDirectory.path}/$toolName';
    return await File(toolPath).exists();
  }
  
  Future<bool> installTool(String toolName, {Function(double)? onProgress}) async {
    try {
      final url = AppConstants.networkTools[toolName];
      if (url == null) return false;
      
      onProgress?.call(0.1);
      
      // Download tool
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return false;
      
      onProgress?.call(0.5);
      
      // Save to tools directory
      final toolFile = File('${_toolsDirectory.path}/$toolName');
      await toolFile.writeAsBytes(response.bodyBytes);
      
      onProgress?.call(0.8);
      
      // Make executable
      await ShellExecutor.instance.executeCommand(
        'chmod +x ${toolFile.path}',
        requireRoot: true,
      );
      
      onProgress?.call(1.0);
      
      _toolsStatus[toolName] = true;
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> installDefaultWordlists() async {
    for (final wordlist in AppConstants.defaultWordlists) {
      final file = File('${_wordlistsDirectory.path}/$wordlist');
      if (!await file.exists()) {
        // Create basic wordlists
        await _createDefaultWordlist(wordlist);
      }
    }
  }
  
  Future<void> _createDefaultWordlist(String filename) async {
    final file = File('${_wordlistsDirectory.path}/$filename');
    
    List<String> passwords = [];
    
    switch (filename) {
      case 'common-passwords.txt':
        passwords = [
          'password', '123456', 'password123', 'admin', 'qwerty',
          'letmein', 'welcome', 'monkey', '1234567890', 'abc123'
        ];
        break;
      case 'wifi-passwords.txt':
        passwords = [
          'password', '12345678', 'qwertyuiop', 'password123',
          'admin123', 'welcome123', 'internet', 'wireless'
        ];
        break;
      case 'wps-pins.txt':
        passwords = [
          '12345670', '00000000', '11111111', '22222222',
          '33333333', '44444444', '55555555', '66666666'
        ];
        break;
    }
    
    await file.writeAsString(passwords.join('\n'));
  }
  
  Map<String, bool> get toolsStatus => _toolsStatus;
  
  String get toolsPath => _toolsDirectory.path;
  String get wordlistsPath => _wordlistsDirectory.path;
  String get capturesPath => _capturesDirectory.path;
  String get reportsPath => _reportsDirectory.path;
}