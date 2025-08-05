CREATE TABLE licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active',
    'inactive',
    'expired',
    'revoked')),
    tier TEXT NOT NULL DEFAULT 'basic' CHECK (tier IN ('basic',
    'pro',
    'enterprise')),
    created_by UUID,
    max_devices INTEGER DEFAULT 1,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);