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