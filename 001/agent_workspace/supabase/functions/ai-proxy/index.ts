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
        const { provider, model, messages, max_tokens, temperature, stream } = await req.json();

        if (!provider || !model || !messages) {
            throw new Error('Provider, model, and messages are required');
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

        // 验证用户设备绑定状态
        const deviceBindingsResponse = await fetch(`${supabaseUrl}/rest/v1/device_bindings?user_id=eq.${userId}&is_active=eq.true`, {
            headers: {
                'Authorization': `Bearer ${serviceRoleKey}`,
                'apikey': serviceRoleKey
            }
        });

        if (!deviceBindingsResponse.ok) {
            throw new Error('Failed to verify device bindings');
        }

        const deviceBindings = await deviceBindingsResponse.json();
        
        if (deviceBindings.length === 0) {
            return new Response(JSON.stringify({
                error: {
                    code: 'NO_VALID_LICENSE',
                    message: '未找到有效的设备绑定，请先激活许可证'
                }
            }), {
                status: 403,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        let response;
        let tokensUsed = 0;
        let costEstimate = 0;
        const startTime = Date.now();

        if (provider === 'openai') {
            const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
            if (!openaiApiKey) {
                throw new Error('OpenAI API key not configured');
            }

            const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${openaiApiKey}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    model: model,
                    messages: messages,
                    max_tokens: max_tokens || 1000,
                    temperature: temperature || 0.7,
                    stream: stream || false
                })
            });

            if (!openaiResponse.ok) {
                const errorData = await openaiResponse.text();
                throw new Error(`OpenAI API error: ${errorData}`);
            }

            const data = await openaiResponse.json();
            response = data;
            tokensUsed = data.usage?.total_tokens || 0;
            
            // 简化的成本估算（实际应用中应使用准确的价格表）
            if (model.includes('gpt-4')) {
                costEstimate = tokensUsed * 0.00006; // 近似价格
            } else {
                costEstimate = tokensUsed * 0.000002;
            }
        }
        
        else if (provider === 'anthropic') {
            const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY');
            if (!anthropicApiKey) {
                throw new Error('Anthropic API key not configured');
            }

            // 转换消息格式为Anthropic格式
            let systemMessage = '';
            const userMessages = [];
            
            for (const msg of messages) {
                if (msg.role === 'system') {
                    systemMessage = msg.content;
                } else {
                    userMessages.push({
                        role: msg.role === 'assistant' ? 'assistant' : 'user',
                        content: msg.content
                    });
                }
            }

            const anthropicBody = {
                model: model,
                max_tokens: max_tokens || 1000,
                temperature: temperature || 0.7,
                messages: userMessages
            };

            if (systemMessage) {
                anthropicBody.system = systemMessage;
            }

            const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${anthropicApiKey}`,
                    'Content-Type': 'application/json',
                    'anthropic-version': '2023-06-01'
                },
                body: JSON.stringify(anthropicBody)
            });

            if (!anthropicResponse.ok) {
                const errorData = await anthropicResponse.text();
                throw new Error(`Anthropic API error: ${errorData}`);
            }

            const data = await anthropicResponse.json();
            
            // 转换回OpenAI格式以保持API一致性
            response = {
                choices: [{
                    message: {
                        role: 'assistant',
                        content: data.content[0].text
                    },
                    finish_reason: data.stop_reason
                }],
                usage: {
                    prompt_tokens: data.usage?.input_tokens || 0,
                    completion_tokens: data.usage?.output_tokens || 0,
                    total_tokens: (data.usage?.input_tokens || 0) + (data.usage?.output_tokens || 0)
                }
            };
            
            tokensUsed = response.usage.total_tokens;
            costEstimate = tokensUsed * 0.00008; // Claude近似价格
        }
        
        else if (provider === 'google') {
            const googleApiKey = Deno.env.get('GOOGLE_AI_API_KEY');
            if (!googleApiKey) {
                throw new Error('Google AI API key not configured');
            }

            // 转换消息格式为Google格式
            const parts = [];
            for (const msg of messages) {
                parts.push({ text: `${msg.role}: ${msg.content}` });
            }

            const googleResponse = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${googleApiKey}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    contents: [{ parts: parts }],
                    generationConfig: {
                        maxOutputTokens: max_tokens || 1000,
                        temperature: temperature || 0.7
                    }
                })
            });

            if (!googleResponse.ok) {
                const errorData = await googleResponse.text();
                throw new Error(`Google AI API error: ${errorData}`);
            }

            const data = await googleResponse.json();
            
            // 转换为OpenAI格式
            response = {
                choices: [{
                    message: {
                        role: 'assistant',
                        content: data.candidates[0].content.parts[0].text
                    },
                    finish_reason: 'stop'
                }],
                usage: {
                    prompt_tokens: 0, // Google API不直接提供token计数
                    completion_tokens: 0,
                    total_tokens: 0
                }
            };
            
            tokensUsed = Math.ceil(data.candidates[0].content.parts[0].text.length / 4); // 估算
            costEstimate = tokensUsed * 0.000001; // Gemini近似价格
        }
        
        else {
            throw new Error(`Unsupported provider: ${provider}`);
        }

        const duration = Date.now() - startTime;

        // 记录AI使用日志
        const logData = {
            user_id: userId,
            model_provider: provider,
            model_name: model,
            tokens_used: tokensUsed,
            cost_estimate: costEstimate,
            request_data: {
                messages: messages,
                max_tokens: max_tokens,
                temperature: temperature
            },
            response_data: {
                finish_reason: response.choices[0].finish_reason,
                content_length: response.choices[0].message.content.length
            },
            duration_ms: duration
        };

        await fetch(`${supabaseUrl}/rest/v1/ai_usage_logs`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${serviceRoleKey}`,
                'apikey': serviceRoleKey,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(logData)
        });

        return new Response(JSON.stringify({
            data: {
                response: response,
                usage: {
                    tokensUsed: tokensUsed,
                    costEstimate: costEstimate,
                    duration: duration
                }
            }
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('AI proxy error:', error);

        const errorResponse = {
            error: {
                code: 'AI_PROXY_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});