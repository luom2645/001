# NovelForge Sentinel Pro - 更新版部署指南

**作者**: MiniMax Agent  
**日期**: 2025-08-06  
**版本**: v1.1 (安全修复版)

---

## 🚨 重要安全更新

**在部署到生产环境前，必须应用以下安全修复！**

### 存储桶安全策略修复

**问题:** 原始版本的存储桶创建脚本存在严重安全漏洞，允许公共读写访问。

**解决方案:** 使用修复版本的存储桶创建脚本：

```bash
# 1. 备份原始文件
mv supabase/functions/create-bucket-novel-documents-temp/index.ts supabase/functions/create-bucket-novel-documents-temp/index.ts.original
mv supabase/functions/create-bucket-user-avatars-temp/index.ts supabase/functions/create-bucket-user-avatars-temp/index.ts.original

# 2. 使用安全修复版本
mv supabase/functions/create-bucket-novel-documents-temp/index.ts.fixed supabase/functions/create-bucket-novel-documents-temp/index.ts
mv supabase/functions/create-bucket-user-avatars-temp/index.ts.fixed supabase/functions/create-bucket-user-avatars-temp/index.ts
```

---

## 系统架构概览

### 🏗️ 技术栈
- **后端**: Supabase (PostgreSQL + Edge Functions)
- **前端**: HTML/CSS/JavaScript (原型) → Flutter Desktop (计划)
- **数据库**: PostgreSQL with RLS
- **存储**: Supabase Storage with 安全策略
- **认证**: Supabase Auth with JWT
- **安全**: TLS 1.3 + 设备绑定 + 多级权限

---

## 📋 部署前检查清单

### 1. 安全配置检查
- [ ] 确认使用修复版存储桶脚本
- [ ] 验证所有RLS策略已启用
- [ ] 检查环境变量配置
- [ ] 确认CORS策略适当配置

### 2. 数据库部署
- [ ] 创建所有必需的表
- [ ] 应用数据库迁移
- [ ] 启用RLS策略
- [ ] 创建数据库索引

### 3. Edge Functions部署
- [ ] 部署所有9个Edge Functions
- [ ] 配置环境变量
- [ ] 测试函数响应
- [ ] 设置速率限制

### 4. 存储配置
- [ ] 创建存储桶（使用安全脚本）
- [ ] 验证存储策略
- [ ] 测试文件上传权限
- [ ] 确认用户隔离有效

---

## 🚀 详细部署步骤

### 步骤1: Supabase项目设置

1. **创建Supabase项目**
```bash
# 登录Supabase
npx supabase login

# 初始化项目
npx supabase init

# 关联远程项目
npx supabase link --project-ref YOUR_PROJECT_REF
```

2. **配置环境变量**
在Supabase Dashboard中设置：
- `SUPABASE_URL`: 你的项目URL
- `SUPABASE_ANON_KEY`: 匿名密钥
- `SUPABASE_SERVICE_ROLE_KEY`: 服务角色密钥

### 步骤2: 数据库部署

1. **部署表结构**
```bash
# 部署所有表
npx supabase db push

# 或者手动执行SQL文件