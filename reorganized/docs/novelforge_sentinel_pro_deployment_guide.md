# NovelForge Sentinel Pro - 部署和使用指南

**作者**: MiniMax Agent  
**日期**: 2025-08-05  
**版本**: v1.0

## 系统部署状态

### ✅ 已完成的组件

#### 数据库架构
- ✅ **8个核心表结构**已创建并部署
  - `profiles` - 用户配置表
  - `licenses` - 许可证系统表
  - `device_bindings` - 设备绑定表
  - `novels` - 小说数据表
  - `audit_logs` - 审计日志表
  - `security_events` - 安全事件表
  - `system_notifications` - 系统通知表
  - `ai_usage_logs` - AI使用日志表

- ✅ **数据库索引和优化**已完成
  - 18个性能优化索引
  - 自动更新时间触发器
  - 用户角色获取辅助函数

- ✅ **Row Level Security (RLS) 策略**已部署
  - 三级权限管理系统（admin/reseller/user）
  - 严格的数据隔离机制
  - 创建者可见原则

- ✅ **审计日志系统**已激活
  - 自动记录关键操作
  - 安全事件检测触发器
  - 权限提升检测

#### 存储服务
- ✅ **用户头像存储桶** (`user-avatars`)
  - 大小限制: 5MB
  - 支持格式: 所有图像格式
  - 公开访问权限

- ✅ **小说文档存储桶** (`novel-documents`)
  - 大小限制: 50MB
  - 支持格式: text/*, application/pdf, application/json
  - 公开访问权限

#### Edge Functions
- ✅ **device-verification** - 设备验证服务
  - URL: `https://fibvxpklqrinabevpfgq.supabase.co/functions/v1/device-verification`
  - 状态: ACTIVE
  - 功能: 设备绑定、验证、指纹检测

- ✅ **license-management** - 许可证管理服务
  - URL: `https://fibvxpklqrinabevpfgq.supabase.co/functions/v1/license-management`
  - 状态: ACTIVE
  - 功能: 卡密生成、验证、管理、查询

- ✅ **ai-proxy** - AI模型代理服务
  - URL: `https://fibvxpklqrinabevpfgq.supabase.co/functions/v1/ai-proxy`
  - 状态: ACTIVE
  - 支持: OpenAI, Anthropic, Google AI
  - 功能: 统一API接口、费用统计、使用日志

- ✅ **security-monitoring** - 安全监控服务
  - URL: `https://fibvxpklqrinabevpfgq.supabase.co/functions/v1/security-monitoring`
  - 状态: ACTIVE
  - 功能: 威胁检测、事件报告、自动扫描

- ✅ **file-upload** - 文件上传服务
  - URL: `https://fibvxpklqrinabevpfgq.supabase.co/functions/v1/file-upload`
  - 状态: ACTIVE
  - 功能: 安全文件上传、头像管理、小说存储

- ✅ **admin-setup** - 管理员设置服务
  - URL: `https://fibvxpklqrinabevpfgq.supabase.co/functions/v1/admin-setup`
  - 状态: ACTIVE
  - 功能: 账号创建、角色管理、权限设置

- ✅ **security-scan-cron** - 定时安全扫描
  - URL: `https://fibvxpklqrinabevpfgq.supabase.co/functions/v1/security-scan-cron`
  - 状态: ACTIVE
  - 调度: 每小时执行 (`0 */1 * * *`)
  - 功能: 自动威胁检济、安全事件生成

#### 管理员账号
- ✅ **默认管理员账号**已创建
  - 用户名: `luom`
  - 邮箱: `luom@novelforge.com`
  - 密码: `luom2645@Gmai.com`
  - 角色: `admin` (一级管理)
  - 状态: 已激活
  - User ID: `360198ea-2d58-46f0-8b0d-671cb98ff402`

#### 自动化服务
- ✅ **定时安全扫描**已配置
  - 执行频率: 每小时
  - 扫描内容: 暴力破解、API滥用、异常激活
  - 自动报告: 高危事件自动通知管理员