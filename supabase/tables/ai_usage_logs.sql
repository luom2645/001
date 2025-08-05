CREATE TABLE ai_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    model_provider TEXT NOT NULL CHECK (model_provider IN ('openai',
    'anthropic',
    'google',
    'local')),
    model_name TEXT NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    cost_estimate DECIMAL(10,6),
    request_data JSONB,
    response_data JSONB,
    duration_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);