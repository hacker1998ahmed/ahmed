import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();
  
  static PermissionManager get instance => _instance;
  
  Future<bool> requestAllPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.phone,
      Permission.camera,
      Permission.microphone,
    ];
    
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    return statuses.values.every((status) => 
        status == PermissionStatus.granted || 
        status == PermissionStatus.limited);
  }
  
  Future<bool> hasStoragePermission() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    
    if (androidInfo.version.sdkInt >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }
  
  Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted ||
           await Permission.locationWhenInUse.isGranted;
  }
  
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}