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
psql -h your-host -U postgres -d postgres -f supabase/tables/profiles.sql
# 重复执行所有表的SQL文件
```

2. **应用迁移**
```bash
npx supabase migration up
```

### 步骤3: Edge Functions部署

1. **部署所有函数**
```bash
# 批量部署所有函数
npx supabase functions deploy admin-setup
npx supabase functions deploy ai-proxy
npx supabase functions deploy device-verification
npx supabase functions deploy file-upload
npx supabase functions deploy license-management
npx supabase functions deploy security-monitoring
npx supabase functions deploy security-scan-cron
```

2. **配置定时任务**
```bash
# 部署定时安全扫描
npx supabase functions deploy security-scan-cron --schedule "0 2 * * *"
```

### 步骤4: 存储配置（关键安全步骤）

1. **创建安全存储桶**
```bash
# 使用修复版脚本创建存储桶
curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/create-bucket-novel-documents-temp' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json'

curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/create-bucket-user-avatars-temp' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json'
```

2. **验证存储安全**
```sql
-- 检查存储策略
SELECT * FROM storage.policies WHERE bucket_id IN ('novel-documents', 'user-avatars');
```

---

## 🔧 管理员设置

### 创建默认管理员账户

1. **运行管理员设置函数**
```bash
curl -X POST 'https://YOUR_PROJECT.supabase.co/functions/v1/admin-setup' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "create_admin",
    "username": "luom",
    "email": "luom2645@gmail.com",
    "password": "luom2645@Gmail.com"
  }'
```

2. **验证管理员权限**
```sql
SELECT id, email, role FROM profiles WHERE role = 'admin';
```

---

## 🧪 功能测试

### 1. 认证测试
```javascript
// 测试用户注册
const { data, error } = await supabase.auth.signUp({
  email: 'test@example.com',
  password: 'test123456'
})

// 测试用户登录
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'test@example.com', 
  password: 'test123456'
})
```

### 2. 权限测试
```javascript
// 测试用户只能访问自己的数据
const { data, error } = await supabase
  .from('novels')
  .select('*')
  // 应该只返回当前用户的小说
```

### 3. 存储测试
```javascript
// 测试文件上传（用户只能上传到自己的文件夹）
const { data, error } = await supabase.storage
  .from('novel-documents')
  .upload(`${user.id}/test.txt`, file)
```

---

## 📊 监控和维护

### 1. 健康检查端点
```bash
# 检查所有Edge Functions状态
curl https://YOUR_PROJECT.supabase.co/functions/v1/admin-setup -I
curl https://YOUR_PROJECT.supabase.co/functions/v1/ai-proxy -I
# ... 检查所有其他函数
```

### 2. 数据库性能监控
```sql
-- 检查慢查询
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- 检查索引使用情况
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### 3. 安全事件监控
```sql
-- 查看最近的安全事件
SELECT * FROM security_events 
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY severity DESC, created_at DESC;
```

---

## 🔒 安全配置建议

### 1. 生产环境CORS设置
```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://yourdomain.com', // 不要使用 '*'
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};
```

### 2. 速率限制配置
在Supabase Dashboard中为每个函数设置适当的速率限制：
- `ai-proxy`: 100请求/分钟
- `device-verification`: 10请求/分钟
- `file-upload`: 20请求/分钟
- 其他函数: 60请求/分钟

### 3. 环境变量安全
```bash
# 确保敏感信息通过环境变量传递
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key" 
export GOOGLE_API_KEY="your-google-key"
```

---

## 🆘 故障排除

### 常见问题

1. **存储桶访问被拒绝**
   - 检查是否使用了修复版的存储桶创建脚本
   - 验证用户是否已正确认证

2. **Edge Function超时**
   - 检查函数日志: `npx supabase functions logs`
   - 验证环境变量是否正确设置

3. **RLS策略阻止访问**
   - 确认用户角色正确设置
   - 检查策略是否正确应用

### 日志查看
```bash
# 查看函数日志
npx supabase functions logs --function-name ai-proxy

# 查看数据库日志
npx supabase logs db
```

---

## 📞 支持

如果遇到部署问题：
1. 检查本指南的故障排除部分
2. 查看项目的issue跟踪系统
3. 确保已应用所有安全修复

**重要提醒:** 此系统包含敏感的安全功能，请在生产部署前进行充分测试。
