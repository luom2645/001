import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import '../security/device_security.dart';
import '../security/audit_logger.dart';
import '../../utils/constants.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuditLogger _auditLogger = AuditLogger();
  
  User? _currentUser;
  bool _isAuthenticated = false;
  String? _deviceId;
  bool _isDeviceBound = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDeviceBound => _isDeviceBound;
  String? get deviceId => _deviceId;

  /// 初始化认证服务
  Future<void> initialize() async {
    try {
      // 获取保存的会话信息
      final token = await _storage.read(key: StorageKeys.userToken);
      _deviceId = await _storage.read(key: StorageKeys.deviceId);
      
      if (token != null && _deviceId != null) {
        // 验证设备绑定
        _isDeviceBound = await DeviceSecurity.verifyDeviceBinding(_deviceId!);
        
        if (_isDeviceBound) {
          // 恢复用户会话
          final response = await _supabase.auth.getUser();
          if (response.user != null) {
            _currentUser = response.user;
            _isAuthenticated = true;
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('认证服务初始化失败: $e');
    }
  }

  /// 用户登录
  Future<AuthResult> signIn(String email, String password) async {
    try {
      // 检查设备绑定
      final deviceInfo = await DeviceSecurity.getDeviceInfo();
      final currentDeviceId = DeviceSecurity.generateDeviceId(deviceInfo);
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        _deviceId = currentDeviceId;
        
        // 验证或创建设备绑定
        final bindingResult = await _verifyOrCreateDeviceBinding(response.user!.id, currentDeviceId);
        
        if (bindingResult.success) {
          _isAuthenticated = true;
          _isDeviceBound = true;
          
          // 保存认证信息
          await _storage.write(key: StorageKeys.userToken, value: response.session?.accessToken);
          await _storage.write(key: StorageKeys.deviceId, value: currentDeviceId);
          await _storage.write(key: StorageKeys.lastSession, value: DateTime.now().toIso8601String());
          
          // 记录登录成功事件
          await _auditLogger.logLoginEvent(
            success: true,
            method: 'email_password',
            userId: response.user!.id,
          );
          
          notifyListeners();
          return AuthResult(success: true, message: '登录成功');
        } else {
          await signOut();
          return AuthResult(success: false, message: bindingResult.message);
        }
      }
      
      return AuthResult(success: false, message: '登录失败');
    } on AuthException catch (e) {
      // 记录登录失败事件
      await _auditLogger.logLoginEvent(
        success: false,
        method: 'email_password',
        failureReason: e.message,
      );
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      // 记录登录失败事件
      await _auditLogger.logLoginEvent(
        success: false,
        method: 'email_password',
        failureReason: e.toString(),
      );
      return AuthResult(success: false, message: ErrorMessages.unknownError);
    }
  }

  /// 用户注册
  Future<AuthResult> signUp(String email, String password, String fullName) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      
      if (response.user != null) {
        return AuthResult(success: true, message: '注册成功，请查收邮件进行验证');
      }
      
      return AuthResult(success: false, message: '注册失败');
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: ErrorMessages.unknownError);
    }
  }

  /// 用户登出
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      
      // 清理本地存储
      await _storage.delete(key: StorageKeys.userToken);
      await _storage.delete(key: StorageKeys.lastSession);
      
      _currentUser = null;
      _isAuthenticated = false;
      _isDeviceBound = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('登出失败: $e');
    }
  }

  /// 验证或创建设备绑定
  Future<AuthResult> _verifyOrCreateDeviceBinding(String userId, String deviceId) async {
    try {
      final response = await _supabase.functions.invoke(
        'device-verification',
        body: {
          'action': 'verify_or_bind',
          'user_id': userId,
          'device_id': deviceId,
          'device_info': await DeviceSecurity.getDeviceInfo(),
        },
      );
      
      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return AuthResult(
          success: data['success'] ?? false,
          message: data['message'] ?? '',
        );
      }
      
      return AuthResult(success: false, message: '设备验证失败');
    } catch (e) {
      return AuthResult(success: false, message: ErrorMessages.deviceBindingError);
    }
  }

  /// 重置密码
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult(success: true, message: '重置邮件已发送');
    } on AuthException catch (e) {
      return AuthResult(success: false, message: e.message);
    } catch (e) {
      return AuthResult(success: false, message: ErrorMessages.unknownError);
    }
  }

  /// 检查会话有效性
  Future<bool> isSessionValid() async {
    try {
      final lastSession = await _storage.read(key: StorageKeys.lastSession);
      if (lastSession != null) {
        final sessionTime = DateTime.parse(lastSession);
        final now = DateTime.now();
        return now.difference(sessionTime).inSeconds < AppConstants.sessionTimeout;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// 认证结果类
class AuthResult {
  final bool success;
  final String message;
  
  AuthResult({required this.success, required this.message});
}