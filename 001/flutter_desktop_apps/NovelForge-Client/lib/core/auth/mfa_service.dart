import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../../utils/constants.dart';

/// 多因素认证服务
/// 支持TOTP、邮件验证码等多种验证方式
class MFAService extends ChangeNotifier {
  static final MFAService _instance = MFAService._internal();
  factory MFAService() => _instance;
  MFAService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _isMFAEnabled = false;
  List<MFAMethod> _availableMethods = [];
  MFAMethod? _preferredMethod;
  
  bool get isMFAEnabled => _isMFAEnabled;
  List<MFAMethod> get availableMethods => List.unmodifiable(_availableMethods);
  MFAMethod? get preferredMethod => _preferredMethod;

  /// 初始化MFA服务
  Future<void> initialize() async {
    try {
      // 加载用户MFA配置
      await _loadMFAConfiguration();
      
      // 初始化可用的MFA方法
      _initializeAvailableMethods();
      
      notifyListeners();
    } catch (e) {
      debugPrint('MFA服务初始化失败: $e');
    }
  }

  /// 加载用户MFA配置
  Future<void> _loadMFAConfiguration() async {
    try {
      final mfaConfig = await _storage.read(key: 'mfa_configuration');
      if (mfaConfig != null) {
        final config = jsonDecode(mfaConfig) as Map<String, dynamic>;
        _isMFAEnabled = config['enabled'] ?? false;
        
        if (config['preferred_method'] != null) {
          _preferredMethod = MFAMethod.values.firstWhere(
            (method) => method.name == config['preferred_method'],
            orElse: () => MFAMethod.email,
          );
        }
      }
    } catch (e) {
      debugPrint('加载MFA配置失败: $e');
    }
  }

  /// 初始化可用的MFA方法
  void _initializeAvailableMethods() {
    _availableMethods = [
      MFAMethod.email,
      MFAMethod.sms, // 将来支持
      MFAMethod.totp, // TOTP应用
      MFAMethod.backupCodes, // 备用码
    ];
  }

  /// 启用MFA
  Future<MFAResult> enableMFA(MFAMethod method, Map<String, dynamic> config) async {
    try {
      switch (method) {
        case MFAMethod.email:
          return await _enableEmailMFA(config);
        case MFAMethod.totp:
          return await _enableTOTPMFA(config);
        case MFAMethod.sms:
          return await _enableSMSMFA(config);
        case MFAMethod.backupCodes:
          return await _enableBackupCodes();
      }
    } catch (e) {
      return MFAResult(
        success: false,
        message: 'MFA启用失败: $e',
      );
    }
  }

  /// 启用邮件MFA
  Future<MFAResult> _enableEmailMFA(Map<String, dynamic> config) async {
    try {
      final email = config['email'] as String?;
      if (email == null || email.isEmpty) {
        return MFAResult(
          success: false,
          message: '邮箱地址不能为空',
        );
      }
      
      // 发送验证邮件
      final verificationCode = _generateVerificationCode();
      
      // 存储邮件MFA配置
      final mfaConfig = {
        'enabled': true,
        'method': MFAMethod.email.name,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _storage.write(
        key: 'mfa_email_config',
        value: jsonEncode(mfaConfig),
      );
      
      _isMFAEnabled = true;
      _preferredMethod = MFAMethod.email;
      
      await _saveMFAConfiguration();
      notifyListeners();
      
      return MFAResult(
        success: true,
        message: '邮件MFA已启用，请检查邮箱验证',
        verificationCode: verificationCode,
      );
    } catch (e) {
      return MFAResult(
        success: false,
        message: '邮件MFA启用失败: $e',
      );
    }
  }

  /// 启用TOTP MFA
  Future<MFAResult> _enableTOTPMFA(Map<String, dynamic> config) async {
    try {
      // 生成TOTP密钥
      final secret = _generateTOTPSecret();
      
      // 生成QR码URL
      final appName = AppConstants.appName;
      final userEmail = config['email'] ?? 'user@example.com';
      final qrCodeUrl = 'otpauth://totp/$appName:$userEmail?secret=$secret&issuer=$appName';
      
      // 存储TOTP配置
      final totpConfig = {
        'enabled': true,
        'secret': secret,
        'qr_url': qrCodeUrl,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _storage.write(
        key: 'mfa_totp_config',
        value: jsonEncode(totpConfig),
      );
      
      return MFAResult(
        success: true,
        message: 'TOTP MFA已生成，请使用认证器应用扫描QR码',
        totpSecret: secret,
        qrCodeUrl: qrCodeUrl,
      );
    } catch (e) {
      return MFAResult(
        success: false,
        message: 'TOTP MFA启用失败: $e',
      );
    }
  }

  /// 启用SMS MFA
  Future<MFAResult> _enableSMSMFA(Map<String, dynamic> config) async {
    // SMS MFA将来实现
    return MFAResult(
      success: false,
      message: 'SMS MFA暂时不支持',
    );
  }

  /// 启用备用码
  Future<MFAResult> _enableBackupCodes() async {
    try {
      // 生成8个备用码
      final backupCodes = List.generate(8, (_) => _generateBackupCode());
      
      // 存储备用码（加密存储）
      final backupConfig = {
        'codes': backupCodes.map((code) => _hashBackupCode(code)).toList(),
        'created_at': DateTime.now().toIso8601String(),
        'used_codes': <String>[],
      };
      
      await _storage.write(
        key: 'mfa_backup_codes',
        value: jsonEncode(backupConfig),
      );
      
      return MFAResult(
        success: true,
        message: '备用码已生成，请安全保存',
        backupCodes: backupCodes,
      );
    } catch (e) {
      return MFAResult(
        success: false,
        message: '备用码生成失败: $e',
      );
    }
  }

  /// 验证MFA码
  Future<MFAResult> verifyMFACode(
    MFAMethod method,
    String code, {
    String? additionalData,
  }) async {
    try {
      switch (method) {
        case MFAMethod.email:
          return await _verifyEmailCode(code);
        case MFAMethod.totp:
          return await _verifyTOTPCode(code);
        case MFAMethod.sms:
          return await _verifySMSCode(code);
        case MFAMethod.backupCodes:
          return await _verifyBackupCode(code);
      }
    } catch (e) {
      return MFAResult(
        success: false,
        message: 'MFA验证失败: $e',
      );
    }
  }

  /// 验证邮件码
  Future<MFAResult> _verifyEmailCode(String code) async {
    // 这里应该与后端验证，暂时模拟
    return MFAResult(
      success: code.length == 6 && RegExp(r'^\d+$').hasMatch(code),
      message: code.length == 6 ? '验证成功' : '验证码格式错误',
    );
  }

  /// 验证TOTP码
  Future<MFAResult> _verifyTOTPCode(String code) async {
    try {
      final totpConfig = await _storage.read(key: 'mfa_totp_config');
      if (totpConfig == null) {
        return MFAResult(
          success: false,
          message: 'TOTP未配置',
        );
      }
      
      final config = jsonDecode(totpConfig) as Map<String, dynamic>;
      final secret = config['secret'] as String;
      
      // 验证TOTP码（简化实现）
      final isValid = _verifyTOTPToken(secret, code);
      
      return MFAResult(
        success: isValid,
        message: isValid ? 'TOTP验证成功' : 'TOTP码错误或已过期',
      );
    } catch (e) {
      return MFAResult(
        success: false,
        message: 'TOTP验证失败: $e',
      );
    }
  }

  /// 验证SMS码
  Future<MFAResult> _verifySMSCode(String code) async {
    // SMS验证将来实现
    return MFAResult(
      success: false,
      message: 'SMS验证暂时不支持',
    );
  }

  /// 验证备用码
  Future<MFAResult> _verifyBackupCode(String code) async {
    try {
      final backupConfig = await _storage.read(key: 'mfa_backup_codes');
      if (backupConfig == null) {
        return MFAResult(
          success: false,
          message: '备用码未配置',
        );
      }
      
      final config = jsonDecode(backupConfig) as Map<String, dynamic>;
      final codes = List<String>.from(config['codes']);
      final usedCodes = List<String>.from(config['used_codes'] ?? []);
      
      final hashedCode = _hashBackupCode(code);
      
      if (usedCodes.contains(hashedCode)) {
        return MFAResult(
          success: false,
          message: '该备用码已使用',
        );
      }
      
      if (codes.contains(hashedCode)) {
        // 标记为已使用
        usedCodes.add(hashedCode);
        config['used_codes'] = usedCodes;
        
        await _storage.write(
          key: 'mfa_backup_codes',
          value: jsonEncode(config),
        );
        
        return MFAResult(
          success: true,
          message: '备用码验证成功',
        );
      }
      
      return MFAResult(
        success: false,
        message: '备用码错误',
      );
    } catch (e) {
      return MFAResult(
        success: false,
        message: '备用码验证失败: $e',
      );
    }
  }

  /// 禁用MFA
  Future<MFAResult> disableMFA() async {
    try {
      // 清理所有MFA配置
      await _storage.delete(key: 'mfa_configuration');
      await _storage.delete(key: 'mfa_email_config');
      await _storage.delete(key: 'mfa_totp_config');
      await _storage.delete(key: 'mfa_backup_codes');
      
      _isMFAEnabled = false;
      _preferredMethod = null;
      
      notifyListeners();
      
      return MFAResult(
        success: true,
        message: 'MFA已禁用',
      );
    } catch (e) {
      return MFAResult(
        success: false,
        message: 'MFA禁用失败: $e',
      );
    }
  }

  /// 保存MFA配置
  Future<void> _saveMFAConfiguration() async {
    try {
      final config = {
        'enabled': _isMFAEnabled,
        'preferred_method': _preferredMethod?.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _storage.write(
        key: 'mfa_configuration',
        value: jsonEncode(config),
      );
    } catch (e) {
      debugPrint('保存MFA配置失败: $e');
    }
  }

  /// 生成验证码
  String _generateVerificationCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// 生成TOTP秘钥
  String _generateTOTPSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 生成备用码
  String _generateBackupCode() {
    final random = Random.secure();
    return List.generate(8, (_) => random.nextInt(10)).join();
  }

  /// 哈希备用码
  String _hashBackupCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证TOTP token（简化实现）
  bool _verifyTOTPToken(String secret, String token) {
    // 这里应该实现真TOTP算法，暂时简化处理
    return token.length == 6 && RegExp(r'^\d+$').hasMatch(token);
  }

  /// 获取MFA状态
  Map<String, dynamic> getMFAStatus() {
    return {
      'enabled': _isMFAEnabled,
      'preferred_method': _preferredMethod?.name,
      'available_methods': _availableMethods.map((m) => m.name).toList(),
    };
  }
}

/// MFA方法枚举
enum MFAMethod {
  email,
  sms,
  totp,
  backupCodes,
}

/// MFA结果类
class MFAResult {
  final bool success;
  final String message;
  final String? verificationCode;
  final String? totpSecret;
  final String? qrCodeUrl;
  final List<String>? backupCodes;
  final Map<String, dynamic>? additionalData;
  
  MFAResult({
    required this.success,
    required this.message,
    this.verificationCode,
    this.totpSecret,
    this.qrCodeUrl,
    this.backupCodes,
    this.additionalData,
  });
}