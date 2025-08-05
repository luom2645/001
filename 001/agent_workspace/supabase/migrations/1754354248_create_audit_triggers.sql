-- Migration: create_audit_triggers
-- Created at: 1754354248

-- 创建审计日志触发器函数
CREATE OR REPLACE FUNCTION audit_table_changes()
RETURNS TRIGGER AS $$
DECLARE
    actor_role TEXT;
BEGIN
    -- 获取操作者角色
    actor_role := get_user_role(auth.uid());
    
    -- 记录审计日志（仅针对管理员和代理商的操作）
    IF actor_role IN ('admin', 'reseller') THEN
        INSERT INTO audit_logs (
            actor_id, 
            actor_role, 
            action, 
            target_table, 
            target_id, 
            details
        ) VALUES (
            auth.uid(),
            actor_role,
            TG_OP,
            TG_TABLE_NAME,
            CASE 
                WHEN TG_OP = 'DELETE' THEN OLD.id
                ELSE NEW.id
            END,
            CASE 
                WHEN TG_OP = 'UPDATE' THEN 
                    jsonb_build_object(
                        'old_values', to_jsonb(OLD),
                        'new_values', to_jsonb(NEW)
                    )
                WHEN TG_OP = 'INSERT' THEN 
                    jsonb_build_object('new_values', to_jsonb(NEW))
                WHEN TG_OP = 'DELETE' THEN 
                    jsonb_build_object('deleted_values', to_jsonb(OLD))
                ELSE NULL
            END
        );
    END IF;
    
    RETURN CASE 
        WHEN TG_OP = 'DELETE' THEN OLD
        ELSE NEW
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 为关键表添加审计触发器
CREATE TRIGGER profiles_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON profiles
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

CREATE TRIGGER licenses_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON licenses
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

CREATE TRIGGER device_bindings_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON device_bindings
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

-- 创建安全事件检测函数
CREATE OR REPLACE FUNCTION detect_security_events()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
BEGIN
    user_role := get_user_role(auth.uid());
    
    -- 检测权限提升
    IF TG_TABLE_NAME = 'profiles' AND TG_OP = 'UPDATE' THEN
        IF OLD.role != NEW.role AND NEW.role IN ('admin', 'reseller') THEN
            INSERT INTO security_events (
                event_type,
                severity,
                user_id,
                description,
                details
            ) VALUES (
                'privilege_escalation',
                'high',
                NEW.id,
                '用户权限被提升',
                jsonb_build_object(
                    'old_role', OLD.role,
                    'new_role', NEW.role,
                    'changed_by', auth.uid()
                )
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加安全事件检测触发器
CREATE TRIGGER security_events_trigger
    AFTER UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION detect_security_events();;