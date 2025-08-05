import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../security/device_security.dart';
import '../../utils/constants.dart';

/// 离线认证服务
/// 在网络不可用时提供本地认证功能
class OfflineAuthService extends ChangeNotifier {
  static final OfflineAuthService _instance = OfflineAuthService._internal();
  factory OfflineAuthService() => _instance;
  OfflineAuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isOfflineMode = false;
  String? _cachedUserCredentials;
  DateTime? _lastOnlineSync;
  
  bool get isOfflineMode => _isOfflineMode;
  DateTime? get lastOnlineSync => _lastOnlineSync;

  /// 初始化离线认证服务
  Future<void> initialize() async {
    try {
      // 检查是否有缓存的认证信息
      _cachedUserCredentials = await _storage.read(key: StorageKeys.userToken);
      
      // 获取最后一次在线同步时间
      final lastSyncStr = await _storage.read(key: 'last_online_sync');
      if (lastSyncStr != null) {
        _lastOnlineSync = DateTime.parse(lastSyncStr);
      }
      
      // 检查网络状态
      await _checkNetworkStatus();
      
      notifyListeners();
    } catch (e) {
      debugPrint('离线认证初始化失败: $e');
    }
  }

  /// 检查网络状态
  Future<void> _checkNetworkStatus() async {
    try {
      // 简单的网络检查，实际上应该使用connectivity_plus包
      // 这里为了简化，假设网络可用
      _isOfflineMode = false;
    } catch (e) {
      _isOfflineMode = true;
      debugPrint('网络不可用，切换到离线模式');
    }
  }

  /// 离线登录验证
  Future<OfflineAuthResult> verifyOfflineCredentials(
    String email, 
    String password,
  ) async {
    try {
      if (_cachedUserCredentials == null) {
        return OfflineAuthResult(
          success: false,
          message: '没有缓存的认证信息，请在线登录',
        );
      }
      
      // 获取设备信息用于验证
      final deviceInfo = await DeviceSecurity.getDeviceInfo();
      final deviceId = DeviceSecurity.generateDeviceId(deviceInfo);
      
      // 检查设备绑定
      final isDeviceBound = await DeviceSecurity.verifyDeviceBinding(deviceId);
      if (!isDeviceBound) {
        return OfflineAuthResult(
          success: false,
          message: '设备绑定验证失败，无法离线使用',
        );
      }
      
      // 验证本地存储的凭据
      final success = await _verifyLocalCredentials(email, password);
      
      if (success) {
        return OfflineAuthResult(
          success: true,
          message: '离线登录成功',
          lastOnlineSync: _lastOnlineSync,
        );
      } else {
        return OfflineAuthResult(
          success: false,
          message: '本地凭据验证失败',
        );
      }
    } catch (e) {
      return OfflineAuthResult(
        success: false,
        message: '离线认证失败: $e',
      );
    }
  }

  /// 验证本地凭据
  Future<bool> _verifyLocalCredentials(String email, String password) async {
    try {
      // 获取存储的用户信息
      final storedUserInfo = await _storage.read(key: 'cached_user_info');
      if (storedUserInfo == null) return false;
      
      final userInfo = jsonDecode(storedUserInfo) as Map<String, dynamic>;
      
      // 验证邮箱
      if (userInfo['email'] != email) return false;
      
      // 验证密码哈希
      final passwordHash = _hashPassword(password, userInfo['salt'] ?? '');
      return passwordHash == userInfo['password_hash'];
    } catch (e) {
      debugPrint('本地凭据验证错误: $e');
      return false;
    }
  }

  /// 密码哈希处理
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 缓存用户认证信息（在线登录成功后调用）
  Future<void> cacheUserCredentials({
    required String email,
    required String passwordHash,
    required String salt,
    required String token,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // 存储用户信息
      final userInfo = {
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
        'cached_at': DateTime.now().toIso8601String(),
        ...?additionalInfo,
      };
      
      await _storage.write(
        key: 'cached_user_info',
        value: jsonEncode(userInfo),
      );
      
      // 存储token
      await _storage.write(key: StorageKeys.userToken, value: token);
      
      // 更新最后同步时间
      await _updateLastOnlineSync();
      
      _cachedUserCredentials = token;
      notifyListeners();
    } catch (e) {
      debugPrint('缓存用户凭据失败: $e');
    }
  }

  /// 更新最后在线同步时间
  Future<void> _updateLastOnlineSync() async {
    try {
      _lastOnlineSync = DateTime.now();
      await _storage.write(
        key: 'last_online_sync',
        value: _lastOnlineSync!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('更新同步时间失败: $e');
    }
  }

  /// 检查是否支持离线模式
  Future<bool> canUseOfflineMode() async {
    try {
      // 检查是否有缓存的认证信息
      if (_cachedUserCredentials == null) return false;
      
      // 检查设备绑定
      final deviceInfo = await DeviceSecurity.getDeviceInfo();
      final deviceId = DeviceSecurity.generateDeviceId(deviceInfo);
      return await DeviceSecurity.verifyDeviceBinding(deviceId);
    } catch (e) {
      return false;
    }
  }

  /// 检查离线数据是否过期
  bool isOfflineDataExpired() {
    if (_lastOnlineSync == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastOnlineSync!);
    
    // 离线数据有效期为7天
    return difference.inDays > 7;
  }

  /// 清理离线数据
  Future<void> clearOfflineData() async {
    try {
      await _storage.delete(key: 'cached_user_info');
      await _storage.delete(key: 'last_online_sync');
      await _storage.delete(key: StorageKeys.userToken);
      
      _cachedUserCredentials = null;
      _lastOnlineSync = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('清理离线数据失败: $e');
    }
  }

  /// 尝试重新连接
  Future<void> attemptReconnection() async {
    await _checkNetworkStatus();
    notifyListeners();
  }

  /// 获取离线模式状态信息
  Map<String, dynamic> getOfflineStatus() {
    return {
      'isOfflineMode': _isOfflineMode,
      'hasCache': _cachedUserCredentials != null,
      'lastOnlineSync': _lastOnlineSync?.toIso8601String(),
      'isDataExpired': isOfflineDataExpired(),
      'canUseOffline': _cachedUserCredentials != null && !isOfflineDataExpired(),
    };
  }
}

/// 离线认证结果
class OfflineAuthResult {
  final bool success;
  final String message;
  final DateTime? lastOnlineSync;
  final Map<String, dynamic>? userData;
  
  OfflineAuthResult({
    required this.success,
    required this.message,
    this.lastOnlineSync,
    this.userData,
  });
}