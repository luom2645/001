Deno.serve(async (req) => {
    try {
        console.log('Starting security scan cron job...');
        
        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        // 调用安全监控服务进行威胁扫描
        const scanResponse = await fetch(`${supabaseUrl}/functions/v1/security-monitoring`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${serviceRoleKey}`
            },
            body: JSON.stringify({
                action: 'scan_threats'
            })
        });

        if (!scanResponse.ok) {
            const errorText = await scanResponse.text();
            throw new Error(`Security scan failed: ${errorText}`);
        }

        const scanResults = await scanResponse.json();
        console.log('Security scan completed:', scanResults);

        // 如果发现威胁，记录安全事件
        if (scanResults.data && scanResults.data.threats && scanResults.data.threats.length > 0) {
            for (const threat of scanResults.data.threats) {
                await fetch(`${supabaseUrl}/functions/v1/security-monitoring`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${serviceRoleKey}`
                    },
                    body: JSON.stringify({
                        action: 'report_security_event',
                        eventType: threat.type,
                        severity: threat.severity,
                        description: threat.description,
                        details: threat.details
                    })
                });
            }
        }

        return new Response(JSON.stringify({
            success: true,
            message: `Security scan completed. Found ${scanResults.data?.threats?.length || 0} threats.`,
            timestamp: new Date().toISOString()
        }), {
            headers: { 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('Security scan cron error:', error);

        return new Response(JSON.stringify({
            success: false,
            error: error.message,
            timestamp: new Date().toISOString()
        }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
});