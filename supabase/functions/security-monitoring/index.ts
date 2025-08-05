Deno.serve(async (req) => {
    const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE, PATCH',
        'Access-Control-Max-Age': '86400',
        'Access-Control-Allow-Credentials': 'false'
    };

    if (req.method === 'OPTIONS') {
        return new Response(null, { status: 200, headers: corsHeaders });
    }

    try {
        const { action, eventType, severity, description, details, ip } = await req.json();

        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        if (action === 'report_security_event') {
            if (!eventType || !severity) {
                throw new Error('Event type and severity are required');
            }

            // 获取用户信息(可选)
            let userId = null;
            const authHeader = req.headers.get('authorization');
            if (authHeader) {
                try {
                    const token = authHeader.replace('Bearer ', '');
                    const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
                        headers: {
                            'Authorization': `Bearer ${token}`,
                            'apikey': serviceRoleKey
                        }
                    });
                    if (userResponse.ok) {
                        const userData = await userResponse.json();
                        userId = userData.id;
                    }
                } catch (error) {
                    console.log('Could not get user from token:', error.message);
                }
            }

            // 获取客户端IP地址
            const clientIP = ip || req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown';

            // 创建安全事件记录
            const securityEvent = {
                event_type: eventType,
                severity: severity,
                user_id: userId,
                ip_address: clientIP,
                description: description || '',
                details: details || {},
                resolved: false
            };

            const eventResponse = await fetch(`${supabaseUrl}/rest/v1/security_events`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify(securityEvent)
            });

            if (!eventResponse.ok) {
                const errorText = await eventResponse.text();
                throw new Error(`Failed to create security event: ${errorText}`);
            }

            const event = await eventResponse.json();

            // 如果是高严重性事件，发送通知给管理员
            if (['high', 'critical'].includes(severity)) {
                // 获取所有管理员
                const adminsResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?role=eq.admin`, {
                    headers: {
                        'Authorization': `Bearer ${serviceRoleKey}`,
                        'apikey': serviceRoleKey
                    }
                });

                if (adminsResponse.ok) {
                    const admins = await adminsResponse.json();
                    
                    // 为每个管理员创建通知
                    for (const admin of admins) {
                        const notification = {
                            recipient_id: admin.id,
                            title: `安全警告: ${eventType}`,
                            message: description || `检测到${severity}级别安全事件`,
                            type: severity === 'critical' ? 'error' : 'warning',
                            data: {
                                securityEventId: event[0].id,
                                eventType: eventType,
                                severity: severity,
                                ipAddress: clientIP
                            }
                        };

                        await fetch(`${supabaseUrl}/rest/v1/system_notifications`, {
                            method: 'POST',
                            headers: {
                                'Authorization': `Bearer ${serviceRoleKey}`,
                                'apikey': serviceRoleKey,
                                'Content-Type': 'application/json'
                            },
                            body: JSON.stringify(notification)
                        });
                    }
                }
            }

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '安全事件已记录',
                    event: event[0]
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'scan_threats') {
            // 定期安全扫描功能
            const scanResults = [];

            // 1. 检查连续登录失败的IP
            const failureThreshold = 5; // 5次失败后警告
            const timeWindow = 3600000; // 1小时内
            const cutoffTime = new Date(Date.now() - timeWindow).toISOString();

            const suspiciousEventsResponse = await fetch(
                `${supabaseUrl}/rest/v1/security_events?event_type=eq.login_failure&created_at=gte.${cutoffTime}&select=ip_address`, 
                {
                    headers: {
                        'Authorization': `Bearer ${serviceRoleKey}`,
                        'apikey': serviceRoleKey
                    }
                }
            );

            if (suspiciousEventsResponse.ok) {
                const events = await suspiciousEventsResponse.json();
                const ipCounts = {};
                
                events.forEach(event => {
                    if (event.ip_address && event.ip_address !== 'unknown') {
                        ipCounts[event.ip_address] = (ipCounts[event.ip_address] || 0) + 1;
                    }
                });

                for (const [ip, count] of Object.entries(ipCounts)) {
                    if (count >= failureThreshold) {
                        scanResults.push({
                            type: 'brute_force_attempt',
                            severity: 'high',
                            description: `IP ${ip} 在过去1小时内尝试登录失败 ${count} 次`,
                            details: { ip_address: ip, failure_count: count }
                        });
                    }
                }
            }

            // 2. 检查异常的AI使用量
            const aiThreshold = 100; // 每小时超过100个请求
            const aiUsageResponse = await fetch(
                `${supabaseUrl}/rest/v1/ai_usage_logs?created_at=gte.${cutoffTime}&select=user_id`, 
                {
                    headers: {
                        'Authorization': `Bearer ${serviceRoleKey}`,
                        'apikey': serviceRoleKey
                    }
                }
            );

            if (aiUsageResponse.ok) {
                const usageLogs = await aiUsageResponse.json();
                const userCounts = {};
                
                usageLogs.forEach(log => {
                    if (log.user_id) {
                        userCounts[log.user_id] = (userCounts[log.user_id] || 0) + 1;
                    }
                });

                for (const [userId, count] of Object.entries(userCounts)) {
                    if (count >= aiThreshold) {
                        scanResults.push({
                            type: 'api_abuse',
                            severity: 'medium',
                            description: `用户 ${userId} 在过去1小时内调用AI接口 ${count} 次`,
                            details: { user_id: userId, request_count: count }
                        });
                    }
                }
            }

            // 3. 检查许可证异常激活
            const recentActivationsResponse = await fetch(
                `${supabaseUrl}/rest/v1/device_bindings?activated_at=gte.${cutoffTime}&select=user_id`, 
                {
                    headers: {
                        'Authorization': `Bearer ${serviceRoleKey}`,
                        'apikey': serviceRoleKey
                    }
                }
            );

            if (recentActivationsResponse.ok) {
                const activations = await recentActivationsResponse.json();
                const activationThreshold = 5; // 同一用户短时间内激活多个许可证
                const activationCounts = {};
                
                activations.forEach(activation => {
                    if (activation.user_id) {
                        activationCounts[activation.user_id] = (activationCounts[activation.user_id] || 0) + 1;
                    }
                });

                for (const [userId, count] of Object.entries(activationCounts)) {
                    if (count >= activationThreshold) {
                        scanResults.push({
                            type: 'suspicious_activity',
                            severity: 'medium',
                            description: `用户 ${userId} 在过去1小时内激活了 ${count} 个许可证`,
                            details: { user_id: userId, activation_count: count }
                        });
                    }
                }
            }

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: `安全扫描完成，发现 ${scanResults.length} 个潜在威胁`,
                    threats: scanResults,
                    scanTime: new Date().toISOString()
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'resolve_event') {
            const authHeader = req.headers.get('authorization');
            if (!authHeader) {
                throw new Error('Authentication required');
            }

            const token = authHeader.replace('Bearer ', '');
            const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!userResponse.ok) {
                throw new Error('Invalid authentication token');
            }

            const userData = await userResponse.json();
            const userId = userData.id;

            // 检查用户权限
            const profileResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${userId}`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!profileResponse.ok) {
                throw new Error('Failed to get user profile');
            }

            const profiles = await profileResponse.json();
            
            if (profiles.length === 0 || profiles[0].role !== 'admin') {
                throw new Error('Only administrators can resolve security events');
            }

            const { eventId } = await req.json();
            if (!eventId) {
                throw new Error('Event ID is required');
            }

            // 更新事件状态
            const updateResponse = await fetch(`${supabaseUrl}/rest/v1/security_events?id=eq.${eventId}`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify({
                    resolved: true,
                    resolved_by: userId,
                    resolved_at: new Date().toISOString()
                })
            });

            if (!updateResponse.ok) {
                const errorText = await updateResponse.text();
                throw new Error(`Failed to resolve event: ${errorText}`);
            }

            const resolvedEvent = await updateResponse.json();

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '安全事件已解决',
                    event: resolvedEvent[0]
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else {
            throw new Error('Invalid action');
        }

    } catch (error) {
        console.error('Security monitoring error:', error);

        const errorResponse = {
            error: {
                code: 'SECURITY_MONITORING_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});