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
        const { action, licenseKey, deviceFingerprint, deviceInfo } = await req.json();

        if (!action) {
            throw new Error('Action is required');
        }

        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        // 获取用户信息
        let userId = null;
        const authHeader = req.headers.get('authorization');
        if (authHeader) {
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
        }

        if (action === 'verify_device') {
            if (!deviceFingerprint) {
                throw new Error('Device fingerprint is required for verification');
            }

            // 验证设备绑定
            const deviceResponse = await fetch(`${supabaseUrl}/rest/v1/device_bindings?device_fingerprint=eq.${deviceFingerprint}&is_active=eq.true`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!deviceResponse.ok) {
                throw new Error('Failed to query device bindings');
            }

            const devices = await deviceResponse.json();
            
            if (devices.length === 0) {
                return new Response(JSON.stringify({
                    data: {
                        verified: false,
                        message: '设备未注册或已失效'
                    }
                }), {
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            const device = devices[0];

            // 检查关联的许可证状态
            const licenseResponse = await fetch(`${supabaseUrl}/rest/v1/licenses?id=eq.${device.license_id}`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!licenseResponse.ok) {
                throw new Error('Failed to query license');
            }

            const licenses = await licenseResponse.json();
            
            if (licenses.length === 0 || licenses[0].status !== 'active') {
                return new Response(JSON.stringify({
                    data: {
                        verified: false,
                        message: '许可证无效或已过期'
                    }
                }), {
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            const license = licenses[0];

            // 检查许可证是否过期
            if (license.expires_at && new Date(license.expires_at) < new Date()) {
                return new Response(JSON.stringify({
                    data: {
                        verified: false,
                        message: '许可证已过期'
                    }
                }), {
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            // 更新设备最后活跃时间
            await fetch(`${supabaseUrl}/rest/v1/device_bindings?id=eq.${device.id}`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    last_seen_at: new Date().toISOString()
                })
            });

            return new Response(JSON.stringify({
                data: {
                    verified: true,
                    message: '设备验证成功',
                    license: {
                        tier: license.tier,
                        expiresAt: license.expires_at
                    }
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'bind_device') {
            if (!licenseKey || !deviceFingerprint || !userId) {
                throw new Error('License key, device fingerprint, and user authentication are required for binding');
            }

            // 验证许可证
            const licenseResponse = await fetch(`${supabaseUrl}/rest/v1/licenses?license_key=eq.${licenseKey}`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!licenseResponse.ok) {
                throw new Error('Failed to query license');
            }

            const licenses = await licenseResponse.json();
            
            if (licenses.length === 0) {
                return new Response(JSON.stringify({
                    error: {
                        code: 'INVALID_LICENSE',
                        message: '无效的许可证密钥'
                    }
                }), {
                    status: 400,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            const license = licenses[0];

            if (license.status !== 'active') {
                return new Response(JSON.stringify({
                    error: {
                        code: 'LICENSE_INACTIVE',
                        message: '许可证未激活或已失效'
                    }
                }), {
                    status: 400,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            // 检查许可证是否过期
            if (license.expires_at && new Date(license.expires_at) < new Date()) {
                return new Response(JSON.stringify({
                    error: {
                        code: 'LICENSE_EXPIRED',
                        message: '许可证已过期'
                    }
                }), {
                    status: 400,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            // 检查已绑定的设备数量
            const existingDevicesResponse = await fetch(`${supabaseUrl}/rest/v1/device_bindings?license_id=eq.${license.id}&is_active=eq.true`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!existingDevicesResponse.ok) {
                throw new Error('Failed to query existing devices');
            }

            const existingDevices = await existingDevicesResponse.json();

            if (existingDevices.length >= license.max_devices) {
                return new Response(JSON.stringify({
                    error: {
                        code: 'DEVICE_LIMIT_EXCEEDED',
                        message: `该许可证最多只能绑定 ${license.max_devices} 台设备`
                    }
                }), {
                    status: 400,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            // 检查设备是否已经绑定到其他许可证
            const deviceCheckResponse = await fetch(`${supabaseUrl}/rest/v1/device_bindings?device_fingerprint=eq.${deviceFingerprint}&is_active=eq.true`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!deviceCheckResponse.ok) {
                throw new Error('Failed to check device bindings');
            }

            const existingDevice = await deviceCheckResponse.json();

            if (existingDevice.length > 0) {
                return new Response(JSON.stringify({
                    error: {
                        code: 'DEVICE_ALREADY_BOUND',
                        message: '该设备已绑定到其他许可证'
                    }
                }), {
                    status: 400,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            // 创建设备绑定
            const bindingResponse = await fetch(`${supabaseUrl}/rest/v1/device_bindings`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify({
                    license_id: license.id,
                    user_id: userId,
                    device_fingerprint: deviceFingerprint,
                    device_info: deviceInfo || {},
                    is_active: true
                })
            });

            if (!bindingResponse.ok) {
                const errorText = await bindingResponse.text();
                throw new Error(`Failed to create device binding: ${errorText}`);
            }

            const binding = await bindingResponse.json();

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '设备绑定成功',
                    binding: binding[0],
                    license: {
                        tier: license.tier,
                        expiresAt: license.expires_at
                    }
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else {
            throw new Error('Invalid action');
        }

    } catch (error) {
        console.error('Device verification error:', error);

        const errorResponse = {
            error: {
                code: 'DEVICE_VERIFICATION_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});