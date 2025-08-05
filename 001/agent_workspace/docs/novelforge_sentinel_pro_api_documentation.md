# NovelForge Sentinel Pro - API 文档

**作者**: MiniMax Agent  
**日期**: 2025-08-05  
**版本**: v1.0

## 系统概述

NovelForge Sentinel Pro 是一个企业级的AI小说生成生态系统后端基础设施，提供安全、可扩展的后端服务，支持用户创作、多级管理、数据安全和实时监控。

### 核心功能
- 三级权限管理（一级管理→二级管理→普通管理→普通用户）
- 设备硬件指纹绑定和验证
- 卡密系统（生成、验证、管理）
- AI模型调用代理（OpenAI, Anthropic, Google）
- 安全监控和威胁检测
- 文件上传和存储管理
- 实时通知和消息推送

## 基础信息

### Base URL
```
https://fibvxpklqrinabevpfgq.supabase.co
```

### 认证
所有API请求都需要在请求头中包含认证信息：

```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

### 响应格式

**成功响应**:
```json
{
  "data": {
    "success": true,
    "message": "操作成功",
    "result": { ... }
  }
}
```

**错误响应**:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述"
  }
}
```

## API 端点

### 1. 管理员设置服务

#### 创建默认管理员账号
```http
POST /functions/v1/admin-setup
```

**请求参数**:
```json
{
  "action": "create_admin",
  "email": "luom@novelforge.com",
  "password": "luom2645@Gmai.com",
  "fullName": "luom"
}
```

**成功响应**:
```json
{
  "data": {
    "success": true,
    "message": "管理员账号创建成功",
    "admin": {
      "id": "uuid",
      "email": "luom@novelforge.com",
      "fullName": "luom",
      "role": "admin"
    }
  }
}
```

#### 创建新用户
```http
POST /functions/v1/admin-setup
```

**请求参数**:
```json
{
  "action": "create_user",
  "email": "user@example.com",
  "password": "password123",
  "fullName": "用户姓名",
  "userRole": "user" // user, reseller
}
```

#### 更新用户角色
```http
POST /functions/v1/admin-setup
```

**请求参数**:
```json
{
  "action": "update_user_role",
  "targetUserId": "uuid",
  "newRole": "reseller"
}
```

### 2. 许可证管理服务

#### 生成许可证
```http
POST /functions/v1/license-management
```

**请求参数**:
```json
{
  "action": "generate_licenses",
  "tier": "pro", // basic, pro, enterprise
  "maxDevices": 2,
  "batchCount": 5,
  "expiresAt": "2025-12-31T23:59:59Z" // 可选
}
```

**成功响应**:
```json
{
  "data": {
    "success": true,
    "message": "成功生成 5 个许可证",
    "licenses": [
      {
        "id": "uuid",
        "license_key": "NF-1K2L3M4N5-ABCDEFGH",
        "tier": "pro",
        "max_devices": 2,
        "status": "active",
        "created_at": "2025-08-05T00:00:00Z"
      }
    ]
  }
}
```

#### 更新许可证状态
```http
POST /functions/v1/license-management
```

**请求参数**:
```json
{
  "action": "update_license",
  "licenseKey": "NF-1K2L3M4N5-ABCDEFGH",
  "status": "inactive", // active, inactive, expired, revoked
  "tier": "enterprise",
  "maxDevices": 5
}
```

#### 查询许可证信息
```http
POST /functions/v1/license-management
```

**请求参数**:
```json
{
  "action": "get_license_info",
  "licenseKey": "NF-1K2L3M4N5-ABCDEFGH"
}
```

### 3. 设备验证服务

#### 验证设备
```http
POST /functions/v1/device-verification
```

**请求参数**:
```json
{
  "action": "verify_device",
  "deviceFingerprint": "CPU123+MB456+HD789"
}
```

**成功响应**:
```json
{
  "data": {
    "verified": true,
    "message": "设备验证成功",
    "license": {
      "tier": "pro",
      "expiresAt": "2025-12-31T23:59:59Z"
    }
  }
}
```

#### 绑定设备
```http
POST /functions/v1/device-verification
```

**请求参数**:
```json
{
  "action": "bind_device",
  "licenseKey": "NF-1K2L3M4N5-ABCDEFGH",
  "deviceFingerprint": "CPU123+MB456+HD789",
  "deviceInfo": {
    "os": "Windows 11",
    "cpu": "Intel i7-12700K",
    "memory": "32GB"
  }
}
```

### 4. AI模型代理服务

#### 调用AI模型
```http
POST /functions/v1/ai-proxy
```

**请求参数**:
```json
{
  "provider": "openai", // openai, anthropic, google
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "你是一个专业的小说创作助手"
    },
    {
      "role": "user",
      "content": "请帮我写一个科幻小说的开头"
    }
  ],
  "max_tokens": 1000,
  "temperature": 0.7
}
```

**成功响应**:
```json
{
  "data": {
    "response": {
      "choices": [
        {
          "message": {
            "role": "assistant",
            "content": "生成的小说内容..."
          },
          "finish_reason": "stop"
        }
      ],
      "usage": {
        "total_tokens": 150
      }
    },
    "usage": {
      "tokensUsed": 150,
      "costEstimate": 0.009,
      "duration": 2300
    }
  }
}
```

### 5. 安全监控服务

#### 报告安全事件
```http
POST /functions/v1/security-monitoring
```

**请求参数**:
```json
{
  "action": "report_security_event",
  "eventType": "login_failure", // login_failure, suspicious_activity, api_abuse, unauthorized_access, device_change, privilege_escalation
  "severity": "high", // low, medium, high, critical
  "description": "多次登录尝试失败",
  "details": {
    "ip_address": "192.168.1.100",
    "user_agent": "Mozilla/5.0..."
  }
}
```

#### 威胁扫描
```http
POST /functions/v1/security-monitoring
```

**请求参数**:
```json
{
  "action": "scan_threats"
}
```

#### 解决安全事件
```http
POST /functions/v1/security-monitoring
```

**请求参数**:
```json
{
  "action": "resolve_event",
  "eventId": "uuid"
}
```

### 6. 文件上传服务

#### 上传用户头像
```http
POST /functions/v1/file-upload
```

**请求参数**:
```json
{
  "action": "upload_avatar",
  "fileData": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ...",
  "fileName": "avatar.jpg",
  "fileType": "image/jpeg"
}
```

#### 上传小说文件
```http
POST /functions/v1/file-upload
```

**请求参数**:
```json
{
  "action": "upload_novel",
  "fileData": "data:text/plain;base64,VGhpcyBpcyBteSBub3ZlbC4uLg==",
  "fileName": "my_novel.txt",
  "fileType": "text/plain",
  "metadata": {
    "title": "我的小说",
    "genre": "科幻",
    "tags": ["AI", "未来"]
  }
}
```

## 数据库模型

### 主要表结构

#### profiles - 用户配置表
- `id` (UUID) - 用户ID，关联auth.users
- `role` (TEXT) - 用户角色（admin/reseller/user）
- `reseller_id` (UUID) - 代理商ID，用于层级管理
- `full_name` (TEXT) - 用户姓名
- `avatar_url` (TEXT) - 头像URL
- `device_limit` (INTEGER) - 设备数量限制

#### licenses - 许可证表
- `id` (UUID) - 许可证ID
- `license_key` (TEXT) - 许可证密钥
- `status` (TEXT) - 状态（active/inactive/expired/revoked）
- `tier` (TEXT) - 级别（basic/pro/enterprise）
- `created_by` (UUID) - 创建者ID
- `max_devices` (INTEGER) - 最大设备数
- `expires_at` (TIMESTAMPTZ) - 过期时间

#### device_bindings - 设备绑定表
- `id` (UUID) - 绑定ID
- `license_id` (UUID) - 许可证ID
- `user_id` (UUID) - 用户ID
- `device_fingerprint` (TEXT) - 设备指纹
- `device_info` (JSONB) - 设备信息
- `is_active` (BOOLEAN) - 是否激活

#### novels - 小说数据表
- `id` (UUID) - 小说ID
- `user_id` (UUID) - 作者ID
- `title` (TEXT) - 标题
- `content` (TEXT) - 内容
- `content_encrypted` (BOOLEAN) - 是否加密
- `metadata` (JSONB) - 元数据
- `quality_score` (DECIMAL) - 质量评分
- `word_count` (INTEGER) - 字数
- `status` (TEXT) - 状态（draft/published/archived）

## 权限系统

### 角色层级
1. **admin** - 一级管理：全系统权限
2. **reseller** - 二级管理：可管理自己创建的用户和许可证
3. **user** - 普通用户：只能访问自己的数据

### 数据隔离原则
- 使用Row Level Security (RLS)强制数据隔离
- 创建者可见原则：用户只能看到自己创建或拥有的数据
- 管理员可以查看所有数据，但修改操作会被审计

## 安全特性

### 设备绑定
- 基于CPU+主板+硬盘的硬件指纹
- 支持多设备绑定（根据许可证级别）
- 设备指纹变更自动检测

### 安全监控
- 实时威胁检测（暴力破解、API滥用）
- 自动安全事件报告
- 每小时定时安全扫描
- 全面的审计日志

### 数据保护
- TLS 1.3加密通信
- 可选的端到端加密(E2EE)
- API密钥安全管理
- GDPR合规数据处理

## 错误代码参考

### 认证错误
- `INVALID_TOKEN` - 无效的JWT令牌
- `INSUFFICIENT_PERMISSIONS` - 权限不足
- `USER_NOT_FOUND` - 用户不存在

### 许可证错误
- `INVALID_LICENSE` - 无效的许可证密钥
- `LICENSE_EXPIRED` - 许可证已过期
- `LICENSE_INACTIVE` - 许可证未激活
- `DEVICE_LIMIT_EXCEEDED` - 设备数量超出限制
- `DEVICE_ALREADY_BOUND` - 设备已绑定

### 文件上传错误
- `FILE_TOO_LARGE` - 文件过大
- `INVALID_FILE_TYPE` - 无效的文件类型
- `UPLOAD_FAILED` - 上传失败

### AI服务错误
- `NO_VALID_LICENSE` - 未找到有效许可证
- `AI_API_ERROR` - AI提供商API错误
- `UNSUPPORTED_PROVIDER` - 不支持的AI提供商

## 使用示例

### JavaScript SDK 集成示例

```javascript
class NovelForgeClient {
  constructor(baseUrl, apiKey) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.token = null;
  }

  async setAuthToken(token) {
    this.token = token;
  }

  async request(endpoint, data) {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`,
        'apikey': this.apiKey
      },
      body: JSON.stringify(data)
    });

    const result = await response.json();
    
    if (!response.ok) {
      throw new Error(result.error?.message || 'API request failed');
    }
    
    return result.data;
  }

  // 设备验证
  async verifyDevice(deviceFingerprint) {
    return await this.request('/functions/v1/device-verification', {
      action: 'verify_device',
      deviceFingerprint
    });
  }

  // 绑定设备
  async bindDevice(licenseKey, deviceFingerprint, deviceInfo) {
    return await this.request('/functions/v1/device-verification', {
      action: 'bind_device',
      licenseKey,
      deviceFingerprint,
      deviceInfo
    });
  }

  // AI文本生成
  async generateText(provider, model, messages, options = {}) {
    return await this.request('/functions/v1/ai-proxy', {
      provider,
      model,
      messages,
      max_tokens: options.maxTokens || 1000,
      temperature: options.temperature || 0.7
    });
  }

  // 上传小说
  async uploadNovel(fileData, fileName, metadata) {
    return await this.request('/functions/v1/file-upload', {
      action: 'upload_novel',
      fileData,
      fileName,
      fileType: 'text/plain',
      metadata
    });
  }
}

// 使用示例
const client = new NovelForgeClient(
  'https://fibvxpklqrinabevpfgq.supabase.co',
  'your_anon_key'
);

// 设置用户JWT令牌
client.setAuthToken('user_jwt_token');

// 验证设备
try {
  const result = await client.verifyDevice('CPU123+MB456+HD789');
  console.log('设备验证结果:', result);
} catch (error) {
  console.error('验证失败:', error.message);
}
```

## 注意事项

1. **安全性**: 绝不在客户端存储API密钥或敏感信息
2. **率限制**: 所有API都有内置的率限制，请合理使用
3. **错误处理**: 始终检查API响应的错误状态和错误消息
4. **数据备份**: 对于重要数据，建议定期备份
5. **版本更新**: API可能会更新，请关注版本变更

## 技术支持

如果您在使用过程中遇到问题，请联系技术支持团队或查阅系统日志获取更多信息。

---

*此文档由 MiniMax Agent 生成，版本 v1.0，更新日期: 2025-08-05*