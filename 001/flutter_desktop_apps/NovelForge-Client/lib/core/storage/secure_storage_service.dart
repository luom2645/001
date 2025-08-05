import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../security/device_security.dart';
import '../../utils/constants.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
    lOptions: LinuxOptions(
      useSessionKeyring: true,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Encrypter? _encrypter;
  IV? _iv;
  bool _isInitialized = false;

  /// 初始化加密器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 获取或生成加密密钥
      final deviceInfo = await DeviceSecurity.getDeviceInfo();
      final deviceId = DeviceSecurity.generateDeviceId(deviceInfo);
      
      // 使用设备ID生成加密密钥
      final keyString = _generateEncryptionKey(deviceId);
      final key = Key.fromBase64(keyString);
      
      _encrypter = Encrypter(AES(key));
      _iv = IV.fromSecureRandom(16);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('安全存储初始化失败: $e');
      throw Exception('安全存储初始化失败');
    }
  }

  /// 生成加密密钥
  String _generateEncryptionKey(String deviceId) {
    final combined = '${deviceId}_${AppConstants.appName}_${AppConstants.appVersion}';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return base64.encode(hash.bytes);
  }

  /// 存储加密数据
  Future<void> writeSecure(String key, String value) async {
    if (!_isInitialized) await initialize();
    
    try {
      final encrypted = _encrypter!.encrypt(value, iv: _iv!);
      await _storage.write(key: key, value: encrypted.base64);
    } catch (e) {
      debugPrint('加密存储失败: $e');
      throw Exception('数据存储失败');
    }
  }

  /// 读取加密数据
  Future<String?> readSecure(String key) async {
    if (!_isInitialized) await initialize();
    
    try {
      final encryptedValue = await _storage.read(key: key);
      if (encryptedValue == null) return null;
      
      final encrypted = Encrypted.fromBase64(encryptedValue);
      return _encrypter!.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      debugPrint('数据解密失败: $e');
      return null;
    }
  }

  /// 存储API密钥
  Future<void> storeApiKey(String provider, String apiKey) async {
    await writeSecure('api_key_$provider', apiKey);
  }

  /// 获取API密钥
  Future<String?> getApiKey(String provider) async {
    return await readSecure('api_key_$provider');
  }

  /// 存储用户设置
  Future<void> storeUserSettings(Map<String, dynamic> settings) async {
    final settingsJson = jsonEncode(settings);
    await writeSecure(StorageKeys.userSettings, settingsJson);
  }

  /// 获取用户设置
  Future<Map<String, dynamic>?> getUserSettings() async {
    final settingsJson = await readSecure(StorageKeys.userSettings);
    if (settingsJson == null) return null;
    
    try {
      return jsonDecode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('用户设置解析失败: $e');
      return null;
    }
  }

  /// 存储资源配置
  Future<void> storeResourceSettings(Map<String, dynamic> settings) async {
    final settingsJson = jsonEncode(settings);
    await writeSecure(StorageKeys.resourceSettings, settingsJson);
  }

  /// 获取资源配置
  Future<Map<String, dynamic>?> getResourceSettings() async {
    final settingsJson = await readSecure(StorageKeys.resourceSettings);
    if (settingsJson == null) return null;
    
    try {
      return jsonDecode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('资源配置解析失败: $e');
      return null;
    }
  }

  /// 删除指定键的数据
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('数据删除失败: $e');
    }
  }

  /// 清空所有存储数据
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('清空存储失败: $e');
    }
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// 获取所有存储的键
  Future<Map<String, String>> getAllData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('读取所有数据失败: $e');
      return {};
    }
  }

  /// 验证存储完整性
  Future<bool> verifyStorageIntegrity() async {
    try {
      // 测试写入和读取
      const testKey = 'integrity_test';
      const testValue = 'test_data_12345';
      
      await writeSecure(testKey, testValue);
      final readValue = await readSecure(testKey);
      await delete(testKey);
      
      return readValue == testValue;
    } catch (e) {
      debugPrint('存储完整性验证失败: $e');
      return false;
    }
  }
}

/// 安全存储结果
class SecureStorageResult {
  final bool success;
  final String? data;
  final String? error;

  SecureStorageResult({
    required this.success,
    this.data,
    this.error,
  });
}
