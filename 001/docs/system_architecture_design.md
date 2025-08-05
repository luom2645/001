# NovelForge Sentinel Pro - 系统架构设计

## 1. 系统架构图

```mermaid
graph TD
    subgraph Client-Side (Flutter Desktop App)
        A[UI/UX Layer - Flutter Widgets]
        B[Business Logic - BLoC/Provider]
        C[Data Layer - Repositories]
        D[Native Integration - FFI]
        E[Local LLM Engine - llama.cpp]
        F[Secure Storage - Encrypted DB/Files]

        A --> B --> C
        C --> D
        C --> G
        C --> H
        D --> E
        B --> F
    end

    subgraph Backend (Supabase)
        G[Supabase API Gateway]
        H[Supabase Auth]
        I[Supabase Database - PostgreSQL]
        J[Supabase Storage]
        K[Supabase Edge Functions]
        L[Supabase Realtime]

        G --> H
        G --> I
        G --> J
        G --> K
        G --> L
    end

    subgraph Third-Party Services
        M[OpenAI API]
        N[Anthropic Claude API]
        O[Google Gemini API]
        P[Payment Gateway - Stripe]
        Q[Email Service - Resend]
    end

    C -- "HTTPS (TLS 1.3)" --> G
    H -- "JWT" --> B
    K -- "Secure API Call" --> M
    K -- "Secure API Call" --> N
    K -- "Secure API Call" --> O
    K -- "Secure API Call" --> P
    K -- "Secure API Call" --> Q

    style Client-Side fill:#dae8fc,stroke:#6c8ebf,stroke-width:2px
    style Backend fill:#d5e8d4,stroke:#82b366,stroke-width:2px
    style Third-Party Services fill:#f8cecc,stroke:#b85450,stroke-width:2px
```

## 2. 核心组件设计

### 2.1. Flutter客户端
- **UI/UX Layer**: 使用Flutter的声明式UI框架构建响应式、跨平台的界面。采用`fluent_ui`或`macos_ui`等库来增强平台的原生感。
- **Business Logic**: 采用`BLoC`或`Provider`进行状态管理，分离业务逻辑与UI。
- **Data Layer (Repositories)**: 作为数据访问的抽象层。它决定是从本地安全存储获取数据，还是通过API网关向Supabase请求数据。
- **Native Integration (FFI)**: 通过FFI（Foreign Function Interface）与用Rust/C++编写的原生模块进行高性能通信。该模块负责：
    - 获取设备硬件指纹。
    - 实现反调试、内存保护等底层安全功能。
    - 调用`llama.cpp`库执行本地AI推理。
- **Local LLM Engine**: 集成`llama.cpp`库，负责加载和运行GGUF格式的本地大语言模型。
- **Secure Storage**: 使用加密的本地数据库（如`Sembast`配合加密）或文件来安全地存储用户的E2EE密钥和敏感配置。

### 2.2. Supabase后端
- **API Gateway**: Supabase提供的统一入口，处理所有来自客户端的请求，并进行初步的路由和安全检查。
- **Auth**: 负责用户的注册、登录、密码重置和JWT（JSON Web Token）的签发与验证。是所有权限控制的基础。
- **Database (PostgreSQL)**: 核心数据存储。利用其强大的功能，如JSONB、全文搜索以及通过触发器实现的审计功能。Row Level Security (RLS) 在此层强制执行数据访问策略。
- **Storage**: 用于存储用户头像、文档附件等文件。所有访问都通过Edge Functions进行权限控制，确保安全。
- **Edge Functions**: 无服务器函数，是系统的核心业务逻辑处理单元。
    - **安全代理**: 代理所有对第三方API（AI模型、支付、邮件）的调用，安全地管理API密钥。
    - **业务逻辑**: 处理硬件绑定验证、许可证激活、数据校验等复杂逻辑。
    - **定时任务**: 执行定期的安全扫描和系统维护任务。
- **Realtime**: 通过WebSocket提供实时通信能力，用于实现系统通知和多用户协作功能。

### 2.3. 第三方服务
- **AI Models**: OpenAI, Anthropic, Google Gemini作为云端AI能力提供方，通过Edge Functions安全集成。
- **Payment Gateway**: Stripe等支付服务，同样通过Edge Function处理支付意图的创建和验证，客户端只处理支付UI。
- **Email Service**: Resend等邮件服务，用于发送告警邮件、用户验证邮件等。

## 3. 数据流图

### 用户激活流程
1.  **Flutter App**: 用户输入卡密 -> 调用FFI获取硬件指纹。
2.  **Flutter App**: 将`{key, fingerprint}`发送到`activate-license` Edge Function。
3.  **Edge Function**: 验证JWT -> 查询`licenses`表验证`key` -> 将`fingerprint`与`key`关联并更新数据库。
4.  **Edge Function**: 返回成功/失败响应。

### AI文本生成流程
1.  **Flutter App**: 用户输入Prompt -> 调用Repository中的`generateText`方法。
2.  **Repository**: 判断用户选择的是云端模型还是本地模型。
3.  **本地流程**:
    - **Repository**: 调用FFI接口，将Prompt传递给`llama.cpp`。
    - **llama.cpp**: 推理生成文本 -> 通过FFI返回给Flutter App。
4.  **云端流程**:
    - **Repository**: 将`{prompt, model_choice}`发送到`proxy-ai-service` Edge Function。
    - **Edge Function**: 验证JWT -> 从Supabase Secrets获取对应模型的API Key -> 调用第三方AI API。
    - **AI API**: 返回生成的文本。
    - **Edge Function**: 将文本返回给Flutter App。
