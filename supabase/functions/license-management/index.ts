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
        const { action, licenseKey, tier, maxDevices, expiresAt, status, batchCount } = await req.json();

        if (!action) {
            throw new Error('Action is required');
        }

        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        // 获取用户信息和权限验证
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

        // 获取用户角色
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
        
        if (profiles.length === 0) {
            throw new Error('User profile not found');
        }

        const userRole = profiles[0].role;

        // 只有管理员和代理商可以管理许可证
        if (!['admin', 'reseller'].includes(userRole)) {
            throw new Error('Insufficient permissions');
        }

        if (action === 'generate_licenses') {
            const count = batchCount || 1;
            const licenseData = {
                tier: tier || 'basic',
                max_devices: maxDevices || 1,
                created_by: userId,
                status: 'active'
            };

            if (expiresAt) {
                licenseData.expires_at = expiresAt;
            }

            const licenses = [];
            
            // 批量生成许可证
            for (let i = 0; i < count; i++) {
                // 生成唯一的许可证密钥
                const timestamp = Date.now().toString(36);
                const randomPart = crypto.getRandomValues(new Uint8Array(8))
                    .reduce((acc, val) => acc + val.toString(36).padStart(2, '0'), '');
                const licenseKey = `NF-${timestamp}-${randomPart}`.toUpperCase();

                const licenseToCreate = {
                    ...licenseData,
                    license_key: licenseKey
                };

                const createResponse = await fetch(`${supabaseUrl}/rest/v1/licenses`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${serviceRoleKey}`,
                        'apikey': serviceRoleKey,
                        'Content-Type': 'application/json',
                        'Prefer': 'return=representation'
                    },
                    body: JSON.stringify(licenseToCreate)
                });

                if (!createResponse.ok) {
                    const errorText = await createResponse.text();
                    throw new Error(`Failed to create license: ${errorText}`);
                }

                const license = await createResponse.json();
                licenses.push(license[0]);
            }

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: `成功生成 ${count} 个许可证`,
                    licenses: licenses
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'update_license') {
            if (!licenseKey) {
                throw new Error('License key is required for update');
            }

            // 查找许可证
            const findResponse = await fetch(`${supabaseUrl}/rest/v1/licenses?license_key=eq.${licenseKey}`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!findResponse.ok) {
                throw new Error('Failed to find license');
            }

            const licenses = await findResponse.json();
            
            if (licenses.length === 0) {
                return new Response(JSON.stringify({
                    error: {
                        code: 'LICENSE_NOT_FOUND',
                        message: '许可证不存在'
                    }
                }), {
                    status: 404,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            const license = licenses[0];

            // 权限检查：管理员可以修改所有许可证，代理商只能修改自己创建的
            if (userRole === 'reseller' && license.created_by !== userId) {
                throw new Error('You can only modify licenses you created');
            }

            const updateData = {};
            if (status) updateData.status = status;
            if (tier) updateData.tier = tier;
            if (maxDevices) updateData.max_devices = maxDevices;
            if (expiresAt) updateData.expires_at = expiresAt;

            const updateResponse = await fetch(`${supabaseUrl}/rest/v1/licenses?id=eq.${license.id}`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify(updateData)
            });

            if (!updateResponse.ok) {
                const errorText = await updateResponse.text();
                throw new Error(`Failed to update license: ${errorText}`);
            }

            const updatedLicense = await updateResponse.json();

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '许可证更新成功',
                    license: updatedLicense[0]
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'get_license_info') {
            if (!licenseKey) {
                throw new Error('License key is required');
            }

            const findResponse = await fetch(`${supabaseUrl}/rest/v1/licenses?license_key=eq.${licenseKey}`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (!findResponse.ok) {
                throw new Error('Failed to find license');
            }

            const licenses = await findResponse.json();
            
            if (licenses.length === 0) {
                return new Response(JSON.stringify({
                    error: {
                        code: 'LICENSE_NOT_FOUND',
                        message: '许可证不存在'
                    }
                }), {
                    status: 404,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                });
            }

            const license = licenses[0];

            // 权限检查
            if (userRole === 'reseller' && license.created_by !== userId) {
                throw new Error('Access denied');
            }

            // 获取绑定的设备信息
            const devicesResponse = await fetch(`${supabaseUrl}/rest/v1/device_bindings?license_id=eq.${license.id}&is_active=eq.true`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            let devices = [];
            if (devicesResponse.ok) {
                devices = await devicesResponse.json();
            }

            return new Response(JSON.stringify({
                data: {
                    license: license,
                    devices: devices,
                    deviceCount: devices.length
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else {
            throw new Error('Invalid action');
        }

    } catch (error) {
        console.error('License management error:', error);

        const errorResponse = {
            error: {
                code: 'LICENSE_MANAGEMENT_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});