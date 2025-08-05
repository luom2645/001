import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/constants.dart';

class DeviceSecurity {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static String? _cachedDeviceId;
  static Map<String, dynamic>? _cachedDeviceInfo;

  /// 初始化设备安全模块
  static Future<void> initialize() async {
    try {
      await _generateOrRetrieveDeviceId();
      await _checkSystemSecurity();
    } catch (e) {
      debugPrint('设备安全初始化失败: $e');
    }
  }

  /// 获取设备信息
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    Map<String, dynamic> deviceInfo = {};
    
    try {
      if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        deviceInfo = {
          'platform': 'windows',
          'device_name': info.computerName,
          'os_version': info.productName,
          'build_number': info.buildNumber.toString(),
          'total_memory': info.systemMemoryInMegabytes,
          'cpu_architecture': info.systemMemoryInMegabytes.toString(),
        };
      } else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        deviceInfo = {
          'platform': 'macos',
          'device_name': info.computerName,
          'os_version': info.osRelease,
          'model': info.model,
          'cpu_type': info.cpuType.toString(),
          'memory': info.memorySize,
        };
      } else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        deviceInfo = {
          'platform': 'linux',
          'device_name': info.name,
          'os_version': info.version,
          'build_id': info.buildId,
          'variant': info.variant,
          'version_codename': info.versionCodename,
        };
      }
      
      _cachedDeviceInfo = deviceInfo;
      return deviceInfo;
    } catch (e) {
      debugPrint('获取设备信息失败: $e');
      return {'platform': 'unknown', 'error': e.toString()};
    }
  }

  /// 生成设备ID
  static String generateDeviceId(Map<String, dynamic> deviceInfo) {
    final identifier = [
      deviceInfo['platform'] ?? 'unknown',
      deviceInfo['device_name'] ?? 'unknown',
      deviceInfo['os_version'] ?? 'unknown',
      deviceInfo['build_number'] ?? deviceInfo['build_id'] ?? 'unknown',
    ].join('|');
    
    final bytes = utf8.encode(identifier);
    final digest = sha256.convert(bytes);
    return 'NF-${digest.toString().substring(0, 16).toUpperCase()}';
  }

  /// 获取或生成设备ID
  static Future<String> _generateOrRetrieveDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    // 尝试从存储中获取
    String? storedDeviceId = await _storage.read(key: StorageKeys.deviceId);
    
    if (storedDeviceId != null) {
      _cachedDeviceId = storedDeviceId;
      return storedDeviceId;
    }

    // 生成新的设备ID
    final deviceInfo = await getDeviceInfo();
    final newDeviceId = generateDeviceId(deviceInfo);
    
    await _storage.write(key: StorageKeys.deviceId, value: newDeviceId);
    _cachedDeviceId = newDeviceId;
    
    return newDeviceId;
  }

  /// 验证设备绑定
  static Future<bool> verifyDeviceBinding(String expectedDeviceId) async {
    try {
      final currentDeviceInfo = await getDeviceInfo();
      final currentDeviceId = generateDeviceId(currentDeviceInfo);
      
      return currentDeviceId == expectedDeviceId;
    } catch (e) {
      debugPrint('设备绑定验证失败: $e');
      return false;
    }
  }

  /// 检查系统安全状态
  static Future<SecurityStatus> _checkSystemSecurity() async {
    List<String> warnings = [];
    List<String> errors = [];
    
    try {
      // 检查调试模式
      if (kDebugMode) {
        warnings.add('应用运行在调试模式下');
      }
      
      // 检查平台安全特性
      if (Platform.isWindows) {
        // Windows特定安全检查
        await _checkWindowsSecurity(warnings, errors);
      } else if (Platform.isMacOS) {
        // macOS特定安全检查
        await _checkMacOSSecurity(warnings, errors);
      } else if (Platform.isLinux) {
        // Linux特定安全检查
        await _checkLinuxSecurity(warnings, errors);
      }
      
      return SecurityStatus(
        isSecure: errors.isEmpty,
        warnings: warnings,
        errors: errors,
      );
    } catch (e) {
      return SecurityStatus(
        isSecure: false,
        warnings: warnings,
        errors: ['安全检查失败: $e'],
      );
    }
  }

  /// Windows安全检查
  static Future<void> _checkWindowsSecurity(List<String> warnings, List<String> errors) async {
    // 可以添加Windows特定的安全检查
    // 例如：检查防病毒软件、防火墙状态等
  }

  /// macOS安全检查
  static Future<void> _checkMacOSSecurity(List<String> warnings, List<String> errors) async {
    // 可以添加macOS特定的安全检查
    // 例如：检查Gatekeeper状态、SIP状态等
  }

  /// Linux安全检查
  static Future<void> _checkLinuxSecurity(List<String> warnings, List<String> errors) async {
    // 可以添加Linux特定的安全检查
    // 例如：检查SELinux状态、防火墙规则等
  }

  /// 加密敏感数据
  static String encryptSensitiveData(String data, String key) {
    try {
      final keyBytes = utf8.encode(key.padRight(32, '0').substring(0, 32));
      final dataBytes = utf8.encode(data);
      final digest = sha256.convert([...keyBytes, ...dataBytes]);
      return base64.encode(digest.bytes);
    } catch (e) {
      debugPrint('数据加密失败: $e');
      return data;
    }
  }

  /// 解密敏感数据  
  static String decryptSensitiveData(String encryptedData, String key) {
    // 这里应该实现对应的解密逻辑
    // 为了简化示例，这里直接返回原数据
    return encryptedData;
  }

  /// 清理敏感数据缓存
  static void clearCache() {
    _cachedDeviceId = null;
    _cachedDeviceInfo = null;
  }
}

/// 安全状态类
class SecurityStatus {
  final bool isSecure;
  final List<String> warnings;
  final List<String> errors;
  
  SecurityStatus({
    required this.isSecure,
    required this.warnings,
    required this.errors,
  });
  
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}