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
        const { action, fileData, fileName, fileType, bucket, metadata } = await req.json();

        if (!action) {
            throw new Error('Action is required');
        }

        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        // 验证用户身份
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

        if (action === 'upload_avatar') {
            if (!fileData || !fileName) {
                throw new Error('File data and filename are required');
            }

            // 验证文件类型
            if (!fileType || !fileType.startsWith('image/')) {
                throw new Error('Only image files are allowed for avatars');
            }

            // 验证文件大小（5MB限制）
            const base64Data = fileData.split(',')[1];
            const fileSize = Math.ceil((base64Data.length * 3) / 4);
            const maxSize = 5 * 1024 * 1024; // 5MB

            if (fileSize > maxSize) {
                throw new Error('File size exceeds 5MB limit');
            }

            // 解析base64数据
            const mimeType = fileData.split(';')[0].split(':')[1];
            const binaryData = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));

            // 生成唯一文件名
            const fileExtension = fileName.split('.').pop();
            const uniqueFileName = `${userId}_${Date.now()}.${fileExtension}`;

            // 上传到Supabase Storage
            const uploadResponse = await fetch(`${supabaseUrl}/storage/v1/object/user-avatars/${uniqueFileName}`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'Content-Type': mimeType,
                    'x-upsert': 'true'
                },
                body: binaryData
            });

            if (!uploadResponse.ok) {
                const errorText = await uploadResponse.text();
                throw new Error(`Upload failed: ${errorText}`);
            }

            // 获取公开URL
            const publicUrl = `${supabaseUrl}/storage/v1/object/public/user-avatars/${uniqueFileName}`;

            // 更新用户头像
            const updateResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${userId}`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify({
                    avatar_url: publicUrl
                })
            });

            if (!updateResponse.ok) {
                const errorText = await updateResponse.text();
                throw new Error(`Failed to update profile: ${errorText}`);
            }

            const updatedProfile = await updateResponse.json();

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '头像上传成功',
                    avatarUrl: publicUrl,
                    profile: updatedProfile[0]
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'upload_novel') {
            if (!fileData || !fileName) {
                throw new Error('File data and filename are required');
            }

            // 验证文件类型
            const allowedTypes = ['text/plain', 'application/json', 'text/markdown'];
            if (!fileType || !allowedTypes.includes(fileType)) {
                throw new Error('Only text, JSON, and markdown files are allowed');
            }

            // 验证文件大小（50MB限制）
            const base64Data = fileData.split(',')[1];
            const fileSize = Math.ceil((base64Data.length * 3) / 4);
            const maxSize = 50 * 1024 * 1024; // 50MB

            if (fileSize > maxSize) {
                throw new Error('File size exceeds 50MB limit');
            }

            // 解析文件内容
            const content = atob(base64Data);

            // 创建小说记录
            const novelData = {
                user_id: userId,
                title: metadata?.title || fileName.replace(/\.[^/.]+$/, ''),
                content: content,
                content_encrypted: false,
                metadata: {
                    original_filename: fileName,
                    file_type: fileType,
                    file_size: fileSize,
                    uploaded_at: new Date().toISOString(),
                    ...metadata
                },
                word_count: content.length,
                status: 'draft'
            };

            const novelResponse = await fetch(`${supabaseUrl}/rest/v1/novels`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                },
                body: JSON.stringify(novelData)
            });

            if (!novelResponse.ok) {
                const errorText = await novelResponse.text();
                throw new Error(`Failed to save novel: ${errorText}`);
            }

            const novel = await novelResponse.json();

            // 同时将文件备份到存储
            const mimeType = fileType;
            const binaryData = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));
            const uniqueFileName = `${userId}/${novel[0].id}_${fileName}`;

            await fetch(`${supabaseUrl}/storage/v1/object/novel-documents/${uniqueFileName}`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'Content-Type': mimeType,
                    'x-upsert': 'true'
                },
                body: binaryData
            });

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    message: '小说文件上传成功',
                    novel: novel[0],
                    backupUrl: `${supabaseUrl}/storage/v1/object/public/novel-documents/${uniqueFileName}`
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else if (action === 'get_upload_url') {
            // 生成签名URL用于大文件上传
            if (!fileName || !bucket) {
                throw new Error('Filename and bucket are required');
            }

            const allowedBuckets = ['user-avatars', 'novel-documents'];
            if (!allowedBuckets.includes(bucket)) {
                throw new Error('Invalid bucket');
            }

            const uniqueFileName = `${userId}/${Date.now()}_${fileName}`;
            const expiresIn = 3600; // 1小时有效

            const signedUrlResponse = await fetch(`${supabaseUrl}/storage/v1/object/sign/${bucket}/${uniqueFileName}`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    expiresIn: expiresIn
                })
            });

            if (!signedUrlResponse.ok) {
                const errorText = await signedUrlResponse.text();
                throw new Error(`Failed to generate signed URL: ${errorText}`);
            }

            const signedUrlData = await signedUrlResponse.json();

            return new Response(JSON.stringify({
                data: {
                    success: true,
                    uploadUrl: `${supabaseUrl}${signedUrlData.signedURL}`,
                    fileName: uniqueFileName,
                    expiresIn: expiresIn
                }
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        else {
            throw new Error('Invalid action');
        }

    } catch (error) {
        console.error('File upload error:', error);

        const errorResponse = {
            error: {
                code: 'FILE_UPLOAD_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});