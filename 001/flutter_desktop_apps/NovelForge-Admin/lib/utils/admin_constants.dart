class AdminConstants {
  // Supabase配置 - 管理员专用
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // 应用配置
  static const String appName = 'NovelForge Sentinel Pro';
  static const String appVersion = '1.0.0';
  static const String appDescription = '多级权限管理桌面应用';
  
  // 权限等级
  static const int adminLevel1 = 1; // 一级管理员
  static const int adminLevel2 = 2; // 二级管理员
  static const int adminLevel3 = 3; // 普通管理员
  
  // 权限名称
  static const Map<int, String> adminLevelNames = {
    1: '一级管理员',
    2: '二级管理员', 
    3: '普通管理员',
  };
  
  // 数据刷新间隔
  static const int dashboardRefreshInterval = 30; // 秒
  static const int metricsRefreshInterval = 5; // 秒
  static const int securityScanInterval = 60; // 秒
  
  // 分页配置
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // 卡密配置
  static const List<String> cardTypes = [
    '标准版 (30天)',
    '专业版 (90天)',
    '企业版 (365天)',
  ];
  
  static const Map<String, int> cardTypeDays = {
    '标准版 (30天)': 30,
    '专业版 (90天)': 90,
    '企业版 (365天)': 365,
  };
  
  // 安全配置
  static const int maxFailedLoginAttempts = 5;
  static const int sessionTimeout = 7200; // 2小时
  static const int passwordMinLength = 8;
  
  // UI配置
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 3);
  
  // 本地存储配置
  static const String localStorageDir = 'NovelForgeAdmin';
  static const String adminDataSubDir = 'admin_data';
  static const String reportsSubDir = 'reports';
  static const String cacheSubDir = 'cache';
  
  // 导出配置
  static const List<String> exportFormats = [
    'CSV',
    'Excel',
    'PDF',
  ];
}

class ApiEndpoints {
  static const String adminAuth = '/functions/v1/admin-auth';
  static const String userManagement = '/functions/v1/user-management';
  static const String cardManagement = '/functions/v1/card-management';
  static const String securityMonitoring = '/functions/v1/security-monitoring';
  static const String systemStats = '/functions/v1/system-stats';
  static const String auditLogs = '/functions/v1/audit-logs';
  static const String dataExport = '/functions/v1/data-export';
}

class StorageKeys {
  static const String adminToken = 'admin_token';
  static const String adminLevel = 'admin_level';
  static const String adminInfo = 'admin_info';
  static const String lastLogin = 'last_login';
  static const String permissions = 'permissions';
  static const String preferences = 'preferences';
}

class ErrorMessages {
  static const String networkError = '网络连接失败，请检查网络设置';
  static const String authError = '管理员身份验证失败';
  static const String permissionDenied = '权限不足，无法执行此操作';
  static const String sessionExpired = '会话已过期，请重新登录';
  static const String dataLoadError = '数据加载失败，请重试';
  static const String operationFailed = '操作失败，请重试';
  static const String validationError = '输入数据验证失败';
  static const String unknownError = '发生未知错误，请联系技术支持';
}

class SuccessMessages {
  static const String loginSuccess = '登录成功';
  static const String operationSuccess = '操作成功完成';
  static const String dataExported = '数据导出成功';
  static const String userCreated = '用户创建成功';
  static const String userUpdated = '用户信息更新成功';
  static const String cardGenerated = '卡密生成成功';
  static const String settingsUpdated = '设置更新成功';
}