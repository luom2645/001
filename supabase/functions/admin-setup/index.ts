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
        const { action, email, password, fullName, userRole, targetUserId, newRole } = await req.json();

        if (!action) {
            throw new Error('Action is required');
        }

        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        if (action === 'create_admin') {
            // 创建默认管理员账号
            const adminEmail = email || 'luom@novelforge.com';
            const adminPassword = password || 'luom2645@Gmai.com';
            const adminName = fullName || 'luom';

            // 检查是否已经存在管理员
            const existingAdminResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?role=eq.admin`, {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey
                }
            });

            if (existingAdminResponse.ok) {
                const existingAdmins = await existingAdminResponse.json();
                if (existingAdmins.length > 0) {
                    return new Response(JSON.stringify({
                        data: {
                            success: false,
                            message: '管理员账号已存在',
                            existingAdmin: existingAdmins[0]
                        }
                    }), {
                        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
                    });
                }
            }

            // 使用Supabase Admin API创建用户
            const createUserResponse = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    email: adminEmail,
                    password: adminPassword,
                    email_confirm: true,
                    user_metadata: {
                        full_name: adminName,
                        role: 'admin'
                    }
                })
            });

            if (!createUserResponse.ok) {
                const errorData = await createUserResponse.text();
                throw new Error(`Failed to create admin user: ${errorData}`);
            }

            const userData = await createUserResponse.json();
            const userId = userData.id;

            // 创建管理员profile
            const profileData = {
                id: userId,
                role: 'admin',
                full_name: adminName,
                device_limit: 999 // 管理员无设备限制
            };

            const profileResponse = await fetch(`${supabaseUrl}/rest/v1/profiles`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify(profileData)
            });

            if (!profileResponse.ok) {
                const errorText = await profileResponse.text();
                throw new Error(`Failed to create admin profile: ${errorText}`);
            }

            const profile = await profileResponse.json();

            // 创建欢迎通知
            const welcomeNotification = {
                recipient_id: userId,
                title: '欢迎使用NovelForge Sentinel Pro',
                message: '您的管理员账号已成功创建。您现在可以管理系统的所有功能。',
                type: 'success',
                data: {
                    welcome: true,
                    setupComplete: true
                }
            };

            await fetch(`${supabaseUrl}/rest/v1/system_notifications`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(welcomeNotification)
            });

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '管理员账号创建成功',
                    admin: {
                        id: userId,
                        email: adminEmail,
                        fullName: adminName,
                        role: 'admin'
                    },
                    profile: profile[0],
                    loginCredentials: {
                        email: adminEmail,
                        password: '请使用您设置的密码登录'
                    }
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'create_user') {
            // 验证管理员权限
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

            const currentUser = await userResponse.json();
            const currentUserId = currentUser.id;

            // 获取当前用户角色
            const profileResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${currentUserId}`, {
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

            const currentUserRole = profiles[0].role;

            // 权限检查：只有管理员和代理商可以创建用户
            if (!['admin', 'reseller'].includes(currentUserRole)) {
                throw new Error('Insufficient permissions');
            }

            // 检查是否试图创建比自己等级高或更高的用户
            const roleHierarchy = { 'user': 1, 'reseller': 2, 'admin': 3 };
            const targetRoleLevel = roleHierarchy[userRole] || 1;
            const currentRoleLevel = roleHierarchy[currentUserRole];

            if (targetRoleLevel >= currentRoleLevel) {
                throw new Error('You cannot create users with equal or higher privileges');
            }

            if (!email || !password) {
                throw new Error('Email and password are required');
            }

            // 创建新用户
            const createUserResponse = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    email: email,
                    password: password,
                    email_confirm: true,
                    user_metadata: {
                        full_name: fullName || '',
                        role: userRole || 'user'
                    }
                })
            });

            if (!createUserResponse.ok) {
                const errorData = await createUserResponse.text();
                throw new Error(`Failed to create user: ${errorData}`);
            }

            const newUserData = await createUserResponse.json();
            const newUserId = newUserData.id;

            // 创建profile
            const newProfileData = {
                id: newUserId,
                role: userRole || 'user',
                full_name: fullName || '',
                reseller_id: currentUserRole === 'reseller' ? currentUserId : null,
                device_limit: userRole === 'reseller' ? 10 : 1
            };

            const newProfileResponse = await fetch(`${supabaseUrl}/rest/v1/profiles`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify(newProfileData)
            });

            if (!newProfileResponse.ok) {
                const errorText = await newProfileResponse.text();
                throw new Error(`Failed to create user profile: ${errorText}`);
            }

            const newProfile = await newProfileResponse.json();

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '用户创建成功',
                    user: {
                        id: newUserId,
                        email: email,
                        fullName: fullName,
                        role: userRole || 'user'
                    },
                    profile: newProfile[0]
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'update_user_role') {
            // 更新用户角色
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

            const currentUser = await userResponse.json();
            const currentUserId = currentUser.id;

            // 获取当前用户角色
            const profileResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${currentUserId}`, {
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
                throw new Error('Only administrators can update user roles');
            }

            if (!targetUserId || !newRole) {
                throw new Error('Target user ID and new role are required');
            }

            // 更新用户角色
            const updateResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${targetUserId}`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify({
                    role: newRole
                })
            });

            if (!updateResponse.ok) {
                const errorText = await updateResponse.text();
                throw new Error(`Failed to update user role: ${errorText}`);
            }

            const updatedProfile = await updateResponse.json();

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '用户角色更新成功',
                    profile: updatedProfile[0]
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else {
            throw new Error('Invalid action');
        }

    } catch (error) {
        console.error('Admin setup error:', error);

        const errorResponse = {
            error: {
                code: 'ADMIN_SETUP_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});