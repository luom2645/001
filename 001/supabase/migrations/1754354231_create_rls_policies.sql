-- Migration: create_rls_policies
-- Created at: 1754354231

-- profiles表的RLS策略
CREATE POLICY "Users can view their own profile" 
ON profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON profiles FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" 
ON profiles FOR ALL
USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Resellers can view profiles they created" 
ON profiles FOR SELECT
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  reseller_id = auth.uid()
);

CREATE POLICY "Resellers can manage profiles they created" 
ON profiles FOR UPDATE
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  reseller_id = auth.uid()
);

-- licenses表的RLS策略
CREATE POLICY "Admins can manage all licenses" 
ON licenses FOR ALL
USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Resellers can view licenses they created" 
ON licenses FOR SELECT
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  created_by = auth.uid()
);

CREATE POLICY "Resellers can manage licenses they created" 
ON licenses FOR ALL
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  created_by = auth.uid()
);

-- device_bindings表的RLS策略
CREATE POLICY "Users can view their own device bindings" 
ON device_bindings FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all device bindings" 
ON device_bindings FOR ALL
USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Resellers can view device bindings of their users" 
ON device_bindings FOR SELECT
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  user_id IN (
    SELECT id FROM profiles WHERE reseller_id = auth.uid()
  )
);

-- novels表的RLS策略
CREATE POLICY "Users can manage their own novels" 
ON novels FOR ALL
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all novels" 
ON novels FOR SELECT
USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Resellers can view novels of their users" 
ON novels FOR SELECT
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  user_id IN (
    SELECT id FROM profiles WHERE reseller_id = auth.uid()
  )
);

-- audit_logs表的RLS策略
CREATE POLICY "Admins can view all audit logs" 
ON audit_logs FOR SELECT
USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Resellers can view audit logs of their operations" 
ON audit_logs FOR SELECT
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  (actor_id = auth.uid() OR 
   actor_id IN (
     SELECT id FROM profiles WHERE reseller_id = auth.uid()
   ))
);

-- security_events表的RLS策略
CREATE POLICY "Admins can view all security events" 
ON security_events FOR ALL
USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Users can view their own security events" 
ON security_events FOR SELECT
USING (auth.uid() = user_id);

-- system_notifications表的RLS策略
CREATE POLICY "Users can view their own notifications" 
ON system_notifications FOR SELECT
USING (auth.uid() = recipient_id);

CREATE POLICY "Users can update their own notifications" 
ON system_notifications FOR UPDATE
USING (auth.uid() = recipient_id);

CREATE POLICY "Admins can manage all notifications" 
ON system_notifications FOR ALL
USING (get_user_role(auth.uid()) = 'admin');

-- ai_usage_logs表的RLS策略
CREATE POLICY "Users can view their own AI usage logs" 
ON ai_usage_logs FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all AI usage logs" 
ON ai_usage_logs FOR SELECT
USING (get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Resellers can view AI usage logs of their users" 
ON ai_usage_logs FOR SELECT
USING (
  get_user_role(auth.uid()) = 'reseller' AND 
  user_id IN (
    SELECT id FROM profiles WHERE reseller_id = auth.uid()
  )
);;