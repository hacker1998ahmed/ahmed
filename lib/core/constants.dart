class AppConstants {
  // App Info
  static const String appName = 'WiMax Pentest Tool';
  static const String version = '1.0.0';
  
  // Tool Paths
  static const String toolsDir = '/data/data/com.wimax.pentest/files/tools';
  static const String wordlistsDir = '/data/data/com.wimax.pentest/files/wordlists';
  static const String capturesDir = '/data/data/com.wimax.pentest/files/captures';
  static const String reportsDir = '/data/data/com.wimax.pentest/files/reports';
  
  // Network Tools
  static const Map<String, String> networkTools = {
    'tcpdump': 'https://github.com/the-tcpdump-group/tcpdump/releases/download/tcpdump-4.99.4/tcpdump-4.99.4.tar.gz',
    'arpspoof': 'https://github.com/alobbs/dsniff/archive/refs/heads/master.zip',
    'aircrack-ng': 'https://github.com/aircrack-ng/aircrack-ng/archive/refs/heads/master.zip',
    'reaver': 'https://github.com/t6x/reaver-wps-fork-t6x/archive/refs/heads/master.zip',
    'nmap': 'https://github.com/nmap/nmap/archive/refs/heads/master.zip',
  };
  
  // Default Wordlists
  static const List<String> defaultWordlists = [
    'rockyou.txt',
    'common-passwords.txt',
    'wifi-passwords.txt',
    'wps-pins.txt',
  ];
  
  // Attack Types
  static const List<String> attackTypes = [
    'Network Reconnaissance',
    'ARP Spoofing',
    'MITM Attack',
    'WiFi Handshake Capture',
    'WPA/WPA2 Cracking',
    'WPS PIN Attack',
    'DNS Spoofing',
    'Packet Sniffing',
  ];
  
  // Colors
  static const Map<String, int> statusColors = {
    'success': 0xFF4CAF50,
    'warning': 0xFFFF9800,
    'error': 0xFFF44336,
    'info': 0xFF2196F3,
    'primary': 0xFFDA373D,
  };
}