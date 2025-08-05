class AppConstants {
  // Supabase配置 - 需要从环境变量或配置文件获取
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  
  // 应用配置
  static const String appName = 'NovelForge Client';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI小说创作桌面工具';
  
  // 创作配置
  static const int defaultWordCount = 10000;
  static const int minWordCount = 1000;
  static const int maxWordCount = 50000;
  
  // 资源管理配置
  static const double defaultResourceReservation = 0.25; // 25%
  static const double minResourceReservation = 0.20;     // 20%
  static const double maxResourceReservation = 0.30;     // 30%
  
  // 质量评估配置
  static const int qualityAssessmentBatchSize = 10;
  static const double plotCoherenceWeight = 0.40;
  static const double styleConsistencyWeight = 0.30;
  static const double conflictResolutionWeight = 0.30;
  
  // AI模型配置
  static const List<String> supportedProviders = [
    'openai',
    'anthropic',
    'google',
    'local'
  ];
  
  // 本地存储配置
  static const String localStorageDir = 'NovelForge';
  static const String novelsSubDir = 'novels';
  static const String settingsSubDir = 'settings';
  static const String cacheSubDir = 'cache';
  
  // 安全配置
  static const int memoryCheckInterval = 5000; // 5秒
  static const int maxFailedAttempts = 3;
  static const int sessionTimeout = 3600; // 1小时
  
  // UI配置
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // 创作流程配置
  static const List<String> creationStages = [
    'worldview',      // 世界观设定
    'outline',        // 故事大纲
    'characters',     // 人物小传
    'style',          // 风格指南
    'conflict',       // 核心冲突
  ];
  
  // 文件格式
  static const List<String> supportedFormats = [
    'txt',
    'md',
    'docx',
    'pdf'
  ];
}

class ApiEndpoints {
  static const String aiProxy = '/functions/v1/ai-proxy';
  static const String deviceVerification = '/functions/v1/device-verification';
  static const String fileUpload = '/functions/v1/file-upload';
  static const String securityMonitoring = '/functions/v1/security-monitoring';
}

class StorageKeys {
  static const String userToken = 'user_token';
  static const String deviceId = 'device_id';
  static const String userSettings = 'user_settings';
  static const String apiKeys = 'api_keys';
  static const String lastSession = 'last_session';
  static const String resourceSettings = 'resource_settings';
}

class ErrorMessages {
  static const String networkError = '网络连接失败，请检查网络设置';
  static const String authError = '身份验证失败，请重新登录';
  static const String deviceBindingError = '设备绑定验证失败';
  static const String insufficientResources = '系统资源不足，请调整配置';
  static const String apiKeyMissing = '请配置AI模型API密钥';
  static const String fileAccessError = '文件访问权限不足';
  static const String unknownError = '发生未知错误，请重试';
}
