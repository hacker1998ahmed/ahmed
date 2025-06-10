import '../core/shell_executor.dart';

class PacketInfo {
  final String source;
  final String destination;
  final String protocol;
  final int size;
  final String timestamp;
  final String info;
  final String rawData;

  PacketInfo({
    required this.source,
    required this.destination,
    required this.protocol,
    required this.size,
    required this.timestamp,
    this.info = '',
    this.rawData = '',
  });
}

class PacketAnalyzer {
  final ShellExecutor _shell = ShellExecutor.instance;

  Future<List<PacketInfo>> analyzeCapture(String captureFile) async {
    final packets = <PacketInfo>[];

    try {
      // Use tcpdump to analyze the capture file
      final result = await _shell.executeCommand(
        'tcpdump -r $captureFile -n -t -v',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          final packet = _parsePacketLine(line);
          if (packet != null) {
            packets.add(packet);
          }
        }
      } else {
        throw Exception('Failed to analyze capture: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Packet analysis failed: $e');
    }

    return packets;
  }

  PacketInfo? _parsePacketLine(String line) {
    try {
      // Basic packet parsing - this is simplified
      // In a real implementation, you'd use a proper packet parsing library
      
      String source = '';
      String destination = '';
      String protocol = 'Unknown';
      int size = 0;
      String timestamp = DateTime.now().toString();
      String info = line;

      // Extract IP addresses
      final ipMatch = RegExp(r'(\d+\.\d+\.\d+\.\d+).*?(\d+\.\d+\.\d+\.\d+)').firstMatch(line);
      if (ipMatch != null) {
        source = ipMatch.group(1)!;
        destination = ipMatch.group(2)!;
      }

      // Determine protocol
      if (line.contains('TCP')) {
        protocol = 'TCP';
      } else if (line.contains('UDP')) {
        protocol = 'UDP';
      } else if (line.contains('ICMP')) {
        protocol = 'ICMP';
      } else if (line.contains('ARP')) {
        protocol = 'ARP';
      } else if (line.contains('DNS')) {
        protocol = 'DNS';
      }

      // Extract size (simplified)
      final sizeMatch = RegExp(r'length (\d+)').firstMatch(line);
      if (sizeMatch != null) {
        size = int.parse(sizeMatch.group(1)!);
      }

      if (source.isNotEmpty && destination.isNotEmpty) {
        return PacketInfo(
          source: source,
          destination: destination,
          protocol: protocol,
          size: size,
          timestamp: timestamp,
          info: info,
          rawData: line,
        );
      }
    } catch (e) {
      // Skip malformed packets
    }

    return null;
  }

  Future<Map<String, int>> getProtocolStatistics(String captureFile) async {
    final stats = <String, int>{};

    try {
      final result = await _shell.executeCommand(
        'tcpdump -r $captureFile -n -q',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        
        for (final line in lines) {
          if (line.contains('TCP')) {
            stats['TCP'] = (stats['TCP'] ?? 0) + 1;
          } else if (line.contains('UDP')) {
            stats['UDP'] = (stats['UDP'] ?? 0) + 1;
          } else if (line.contains('ICMP')) {
            stats['ICMP'] = (stats['ICMP'] ?? 0) + 1;
          } else if (line.contains('ARP')) {
            stats['ARP'] = (stats['ARP'] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      // Return empty stats on error
    }

    return stats;
  }

  Future<List<String>> extractCredentials(String captureFile) async {
    final credentials = <String>[];

    try {
      // Look for HTTP POST data that might contain credentials
      final result = await _shell.executeCommand(
        'tcpdump -r $captureFile -A | grep -i "password\\|login\\|user"',
        requireRoot: true,
      );

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        credentials.addAll(lines.where((line) => line.trim().isNotEmpty));
      }
    } catch (e) {
      // Ignore errors - credentials extraction is best effort
    }

    return credentials;
  }

  Future<void> exportToText(String captureFile, String outputFile) async {
    try {
      await _shell.executeCommand(
        'tcpdump -r $captureFile -n -t > $outputFile',
        requireRoot: true,
      );
    } catch (e) {
      throw Exception('Failed to export capture: $e');
    }
  }
}