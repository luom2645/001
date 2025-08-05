import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_security.dart';
import '../../utils/constants.dart';

/// 安全审计日志服务
/// 记录所有安全相关的操作和事件
class AuditLogger {
  static final AuditLogger _instance = AuditLogger._internal();
  factory AuditLogger() => _instance;
  AuditLogger._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  late String _logFilePath;
  final List<AuditLogEntry> _pendingLogs = [];
  Timer? _uploadTimer;
  
  bool _isInitialized = false;
  String? _sessionId;
  String? _deviceId;

  /// 初始化审计日志服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 获取设备ID
      final deviceInfo = await DeviceSecurity.getDeviceInfo();
      _deviceId = DeviceSecurity.generateDeviceId(deviceInfo);
      
      // 生成会话 ID
      _sessionId = _generateSessionId();
      
      // 创建日志文件路径
      await _initializeLogFile();
      
      // 启动定时上传
      _startPeriodicUpload();
      
      // 记录初始化事件
      await logSecurityEvent(
        AuditEventType.systemStart,
        '应用程序启动',
        details: {
          'device_id': _deviceId,
          'session_id': _sessionId,
          'platform': Platform.operatingSystem,
          'app_version': AppConstants.appVersion,
        },
      );
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('审计日志初始化失败: $e');
    }
  }

  /// 初始化日志文件
  Future<void> _initializeLogFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/${AppConstants.localStorageDir}/audit_logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      _logFilePath = '${logDir.path}/audit_$today.json';
    } catch (e) {
      debugPrint('初始化日志文件失败: $e');
    }
  }

  /// 记录安全事件
  Future<void> logSecurityEvent(
    AuditEventType eventType,
    String description, {
    Map<String, dynamic>? details,
    AuditSeverity severity = AuditSeverity.info,
    String? userId,
  }) async {
    try {
      final logEntry = AuditLogEntry(
        id: _generateLogId(),
        sessionId: _sessionId ?? 'unknown',
        deviceId: _deviceId ?? 'unknown',
        userId: userId ?? await _getCurrentUserId(),
        eventType: eventType,
        severity: severity,
        description: description,
        details: details ?? {},
        timestamp: DateTime.now(),
        ipAddress: await _getLocalIPAddress(),
        userAgent: _getUserAgent(),
      );
      
      // 添加到待处理队列
      _pendingLogs.add(logEntry);
      
      // 写入本地文件
      await _writeToLocalFile(logEntry);
      
      // 高优先级事件立即上传
      if (severity == AuditSeverity.critical || severity == AuditSeverity.high) {
        await _uploadLogs(immediate: true);
      }
      
      debugPrint('安全事件已记录: ${eventType.name} - $description');
    } catch (e) {
      debugPrint('记录安全事件失败: $e');
    }
  }

  /// 记录登录事件
  Future<void> logLoginEvent({
    required bool success,
    required String method,
    String? failureReason,
    String? userId,
  }) async {
    await logSecurityEvent(
      success ? AuditEventType.loginSuccess : AuditEventType.loginFailure,
      success ? '登录成功' : '登录失败',
      details: {
        'method': method,
        'failure_reason': failureReason,
        'attempt_time': DateTime.now().toIso8601String(),
      },
      severity: success ? AuditSeverity.info : AuditSeverity.medium,
      userId: userId,
    );
  }

  /// 记录设备绑定事件
  Future<void> logDeviceBindingEvent({
    required bool success,
    required String action,
    String? deviceInfo,
    String? userId,
  }) async {
    await logSecurityEvent(
      success ? AuditEventType.deviceBindingSuccess : AuditEventType.deviceBindingFailure,
      '设备绑定$action',
      details: {
        'action': action,
        'device_info': deviceInfo,
        'binding_time': DateTime.now().toIso8601String(),
      },
      severity: success ? AuditSeverity.info : AuditSeverity.high,
      userId: userId,
    );
  }

  /// 记录数据操作事件
  Future<void> logDataOperation({
    required String operation,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? changes,
    String? userId,
  }) async {
    await logSecurityEvent(
      AuditEventType.dataOperation,
      '数据操作: $operation $resourceType',
      details: {
        'operation': operation,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'changes': changes,
        'operation_time': DateTime.now().toIso8601String(),
      },
      severity: AuditSeverity.info,
      userId: userId,
    );
  }

  /// 记录安全威胁事件
  Future<void> logSecurityThreat({
    required String threatType,
    required String description,
    Map<String, dynamic>? evidence,
    String? userId,
  }) async {
    await logSecurityEvent(
      AuditEventType.securityThreat,
      '安全威胁: $threatType',
      details: {
        'threat_type': threatType,
        'evidence': evidence,
        'detection_time': DateTime.now().toIso8601String(),
      },
      severity: AuditSeverity.critical,
      userId: userId,
    );
  }

  /// 写入本地文件
  Future<void> _writeToLocalFile(AuditLogEntry entry) async {
    try {
      final file = File(_logFilePath);
      final logLine = '${jsonEncode(entry.toJson())}\n';
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      debugPrint('写入本地日志文件失败: $e');
    }
  }

  /// 启动定时上传
  void _startPeriodicUpload() {
    _uploadTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _uploadLogs(),
    );
  }

  /// 上传日志到服务器
  Future<void> _uploadLogs({bool immediate = false}) async {
    if (_pendingLogs.isEmpty) return;
    
    try {
      final logsToUpload = List<AuditLogEntry>.from(_pendingLogs);
      
      // 上传到 Supabase
      final response = await _supabase.functions.invoke(
        'security-monitoring',
        body: {
          'action': 'upload_audit_logs',
          'logs': logsToUpload.map((log) => log.toJson()).toList(),
          'session_id': _sessionId,
          'device_id': _deviceId,
        },
      );
      
      if (response.status == 200) {
        _pendingLogs.clear();
        debugPrint('审计日志上传成功: ${logsToUpload.length} 条');
      } else {
        debugPrint('审计日志上传失败: ${response.status}');
      }
    } catch (e) {
      debugPrint('上传审计日志失败: $e');
    }
  }

  /// 获取当前用户ID
  Future<String?> _getCurrentUserId() async {
    try {
      return _supabase.auth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  /// 获取本地IP地址
  Future<String> _getLocalIPAddress() async {
    try {
      // 这里应该实现真实IP获取，暂时返回默认值
      return '127.0.0.1';
    } catch (e) {
      return 'unknown';
    }
  }

  /// 获取用户代理字符串
  String _getUserAgent() {
    return '${AppConstants.appName}/${AppConstants.appVersion} (${Platform.operatingSystem})';
  }

  /// 生成会话 ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'session_${timestamp}_$random';
  }

  /// 生成日志 ID
  String _generateLogId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'log_${timestamp}_$random';
  }

  /// 获取本地日志文件列表
  Future<List<File>> getLocalLogFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/${AppConstants.localStorageDir}/audit_logs');
      
      if (!await logDir.exists()) {
        return [];
      }
      
      return logDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
    } catch (e) {
      debugPrint('获取本地日志文件失贅: $e');
      return [];
    }
  }

  /// 清理旧日志文件
  Future<void> cleanOldLogs({int keepDays = 30}) async {
    try {
      final logFiles = await getLocalLogFiles();
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      for (final file in logFiles) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          debugPrint('已删除旧日志文件: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('清理旧日志失败: $e');
    }
  }

  /// 关闭审计日志服务
  Future<void> dispose() async {
    _uploadTimer?.cancel();
    
    // 最后一次上传
    await _uploadLogs(immediate: true);
    
    // 记录关闭事件
    await logSecurityEvent(
      AuditEventType.systemShutdown,
      '应用程序关闭',
      details: {
        'session_duration': DateTime.now().difference(
          DateTime.parse(_sessionId?.split('_')[1] ?? DateTime.now().toIso8601String()),
        ).inMinutes,
      },
    );
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'session_id': _sessionId,
      'device_id': _deviceId,
      'pending_logs': _pendingLogs.length,
      'is_initialized': _isInitialized,
      'log_file_path': _logFilePath,
    };
  }
}

/// 审计日志条目
class AuditLogEntry {
  final String id;
  final String sessionId;
  final String deviceId;
  final String? userId;
  final AuditEventType eventType;
  final AuditSeverity severity;
  final String description;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;

  AuditLogEntry({
    required this.id,
    required this.sessionId,
    required this.deviceId,
    this.userId,
    required this.eventType,
    required this.severity,
    required this.description,
    required this.details,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'device_id': deviceId,
      'user_id': userId,
      'event_type': eventType.name,
      'severity': severity.name,
      'description': description,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }
}

/// 审计事件类型
enum AuditEventType {
  systemStart,
  systemShutdown,
  loginSuccess,
  loginFailure,
  logout,
  deviceBindingSuccess,
  deviceBindingFailure,
  dataOperation,
  securityThreat,
  configurationChange,
  fileAccess,
  networkAccess,
  apiCall,
  error,
}

/// 审计事件严重程度
enum AuditSeverity {
  info,
  low,
  medium,
  high,
  critical,
}