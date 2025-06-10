import 'dart:io';
import 'dart:convert';
import 'package:process_run/process_run.dart';

class ShellExecutor {
  static final ShellExecutor _instance = ShellExecutor._internal();
  factory ShellExecutor() => _instance;
  ShellExecutor._internal();
  
  static ShellExecutor get instance => _instance;
  
  bool _isRooted = false;
  
  Future<bool> checkRootAccess() async {
    try {
      final result = await Process.run('su', ['-c', 'id']);
      _isRooted = result.exitCode == 0;
      return _isRooted;
    } catch (e) {
      _isRooted = false;
      return false;
    }
  }
  
  Future<ProcessResult> executeCommand(String command, {
    bool requireRoot = false,
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    try {
      if (requireRoot && !_isRooted) {
        throw Exception('Root access required for this command');
      }
      
      List<String> args;
      String executable;
      
      if (requireRoot) {
        executable = 'su';
        args = ['-c', command];
      } else {
        final parts = command.split(' ');
        executable = parts.first;
        args = parts.skip(1).toList();
      }
      
      return await Process.run(
        executable,
        args,
        workingDirectory: workingDirectory,
        environment: environment,
      );
    } catch (e) {
      return ProcessResult(0, 1, '', 'Error: $e');
    }
  }
  
  Stream<String> executeStreamCommand(String command, {
    bool requireRoot = false,
    String? workingDirectory,
  }) async* {
    try {
      List<String> args;
      String executable;
      
      if (requireRoot) {
        executable = 'su';
        args = ['-c', command];
      } else {
        final parts = command.split(' ');
        executable = parts.first;
        args = parts.skip(1).toList();
      }
      
      final process = await Process.start(
        executable,
        args,
        workingDirectory: workingDirectory,
      );
      
      await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        yield line;
      }
      
      await for (final line in process.stderr.transform(utf8.decoder).transform(const LineSplitter())) {
        yield 'ERROR: $line';
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }
  
  Future<bool> isToolInstalled(String toolName) async {
    final result = await executeCommand('which $toolName');
    return result.exitCode == 0;
  }
  
  Future<String> getNetworkInterface() async {
    final result = await executeCommand('ip route | grep default | awk \'{print \$5}\'');
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
    return 'wlan0'; // fallback
  }
  
  Future<List<String>> getConnectedDevices() async {
    final result = await executeCommand('arp -a');
    if (result.exitCode == 0) {
      return result.stdout.toString().split('\n')
          .where((line) => line.isNotEmpty)
          .toList();
    }
    return [];
  }
}