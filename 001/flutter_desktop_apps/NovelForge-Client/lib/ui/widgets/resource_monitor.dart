import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'glass_panel.dart';

class ResourceMonitor extends StatefulWidget {
  final VoidCallback onClose;
  
  const ResourceMonitor({
    super.key,
    required this.onClose,
  });

  @override
  State<ResourceMonitor> createState() => _ResourceMonitorState();
}

class _ResourceMonitorState extends State<ResourceMonitor>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  late Timer _updateTimer;
  
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;
  int _totalMemory = 8;
  int _usedMemory = 0;
  int _recommendedThreads = 8;
  
  final List<ResourceDataPoint> _cpuHistory = [];
  final List<ResourceDataPoint> _memoryHistory = [];
  
  final List<AIModelStatus> _aiModels = [
    AIModelStatus(
      name: 'GPT-4',
      provider: 'OpenAI',
      status: ModelConnectionStatus.connected,
      icon: Icons.psychology,
      color: AppTheme.primaryNeon,
    ),
    AIModelStatus(
      name: 'Claude',
      provider: 'Anthropic',
      status: ModelConnectionStatus.connected,
      icon: Icons.smart_toy,
      color: AppTheme.secondaryNeon,
    ),
    AIModelStatus(
      name: 'Gemini',
      provider: 'Google',
      status: ModelConnectionStatus.disconnected,
      icon: Icons.auto_awesome,
      color: AppTheme.accentNeon,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startResourceMonitoring();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  void _startResourceMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateResourceData();
    });
    
    // 初始更新
    _updateResourceData();
  }

  void _updateResourceData() {
    setState(() {
      // 模拟CPU和内存使用率数据
      _cpuUsage = 30 + (DateTime.now().millisecond % 40).toDouble();
      _memoryUsage = 40 + (DateTime.now().second % 30).toDouble();
      _usedMemory = ((_totalMemory * _memoryUsage) / 100).round();
      
      // 更新历史数据
      final now = DateTime.now();
      _cpuHistory.add(ResourceDataPoint(timestamp: now, value: _cpuUsage));
      _memoryHistory.add(ResourceDataPoint(timestamp: now, value: _memoryUsage));
      
      // 保持最近30个数据点
      if (_cpuHistory.length > 30) {
        _cpuHistory.removeAt(0);
      }
      if (_memoryHistory.length > 30) {
        _memoryHistory.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.memory,
            color: AppTheme.primaryNeon,
            size: 20,
          ),
          
          const SizedBox(width: 8),
          
          Text(
            '系统资源监控',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          // 系统状态指示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.accentNeon.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentNeon,
                  ),
                ),
                
                const SizedBox(width: 6),
                
                Text(
                  '运行正常',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentNeon,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.expand_more,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 系统资源统计
          Expanded(
            flex: 2,
            child: _buildResourceStats(),
          ),
          
          const SizedBox(width: 16),
          
          // AI模型状态
          Expanded(
            flex: 1,
            child: _buildAIModelsStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceStats() {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // CPU使用率
          Expanded(
            child: _buildResourceItem(
              'CPU使用率',
              '${_cpuUsage.toInt()}%',
              _cpuUsage / 100,
              AppTheme.primaryNeon,
              Icons.speed,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 内存使用
          Expanded(
            child: _buildResourceItem(
              '内存使用',
              '$_usedMemory/${_totalMemory}GB',
              _memoryUsage / 100,
              AppTheme.secondaryNeon,
              Icons.memory,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 推荐线程
          Expanded(
            child: _buildResourceItem(
              '推荐线程',
              '$_recommendedThreads 线程',
              1.0,
              AppTheme.accentNeon,
              Icons.settings,
              hideProgress: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(
    String label,
    String value,
    double progress,
    Color color,
    IconData icon, {
    bool hideProgress = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        if (!hideProgress) ..[
          const SizedBox(height: 8),
          
          SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAIModelsStatus() {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI模型状态',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView.separated(
              itemCount: _aiModels.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final model = _aiModels[index];
                return _buildModelStatusItem(model);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelStatusItem(AIModelStatus model) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: model.color.withOpacity(0.1),
            border: Border.all(
              color: model.color.withOpacity(0.3),
            ),
          ),
          child: Icon(
            model.icon,
            size: 12,
            color: model.color,
          ),
        ),
        
        const SizedBox(width: 8),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              Text(
                model.provider,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(model.status),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ModelConnectionStatus status) {
    switch (status) {
      case ModelConnectionStatus.connected:
        return AppTheme.accentNeon;
      case ModelConnectionStatus.disconnected:
        return AppTheme.textMuted;
      case ModelConnectionStatus.error:
        return AppTheme.dangerNeon;
    }
  }
}

// 数据类定义
class ResourceDataPoint {
  final DateTime timestamp;
  final double value;
  
  ResourceDataPoint({
    required this.timestamp,
    required this.value,
  });
}

class AIModelStatus {
  final String name;
  final String provider;
  final ModelConnectionStatus status;
  final IconData icon;
  final Color color;
  
  AIModelStatus({
    required this.name,
    required this.provider,
    required this.status,
    required this.icon,
    required this.color,
  });
}

enum ModelConnectionStatus {
  connected,
  disconnected,
  error,
}