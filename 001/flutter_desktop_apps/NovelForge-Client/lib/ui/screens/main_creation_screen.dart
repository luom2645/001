import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/app_theme.dart';
import '../../core/auth/auth_service.dart';
import '../widgets/cyber_sidebar.dart';
import '../widgets/creation_workspace.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/resource_monitor.dart';

class MainCreationScreen extends ConsumerStatefulWidget {
  const MainCreationScreen({super.key});

  @override
  ConsumerState<MainCreationScreen> createState() => _MainCreationScreenState();
}

class _MainCreationScreenState extends ConsumerState<MainCreationScreen> {
  int _selectedIndex = 0;
  bool _showAIPanel = true;
  bool _showResourceMonitor = true;

  final List<String> _sectionTitles = [
    '创作中心',
    '作品管理',
    'AI模型',
    '系统设置',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: Row(
          children: [
            // 左侧导航栏
            CyberSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              onLogout: _handleLogout,
            ),
            
            // 主内容区域
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Row(
                      children: [
                        // 主工作区
                        Expanded(
                          flex: _showAIPanel ? 3 : 4,
                          child: _buildMainContent(),
                        ),
                        
                        // AI助手面板
                        if (_showAIPanel)
                          SizedBox(
                            width: 320,
                            child: AIAssistantPanel(
                              onClose: () {
                                setState(() {
                                  _showAIPanel = false;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // 底部资源监控
                  if (_showResourceMonitor)
                    ResourceMonitor(
                      onClose: () {
                        setState(() {
                          _showResourceMonitor = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryNeon.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题
          Text(
            _sectionTitles[_selectedIndex],
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          
          const Spacer(),
          
          // 功能按钮
          _buildTopBarActions(),
        ],
      ),
    );
  }

  Widget _buildTopBarActions() {
    return Row(
      children: [
        // AI面板切换
        IconButton(
          icon: Icon(
            _showAIPanel ? Icons.psychology : Icons.psychology_outlined,
            color: _showAIPanel ? AppTheme.primaryNeon : AppTheme.textSecondary,
          ),
          tooltip: _showAIPanel ? '隐藏AI助手' : '显示AI助手',
          onPressed: () {
            setState(() {
              _showAIPanel = !_showAIPanel;
            });
          },
        ),
        
        // 资源监控切换
        IconButton(
          icon: Icon(
            _showResourceMonitor ? Icons.memory : Icons.memory_outlined,
            color: _showResourceMonitor ? AppTheme.primaryNeon : AppTheme.textSecondary,
          ),
          tooltip: _showResourceMonitor ? '隐藏资源监控' : '显示资源监控',
          onPressed: () {
            setState(() {
              _showResourceMonitor = !_showResourceMonitor;
            });
          },
        ),
        
        const SizedBox(width: 8),
        
        // 用户信息
        _buildUserInfo(),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryNeon.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryNeon,
                  AppTheme.accentNeon,
                ],
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AuthService().currentUser?.email?.split('@').first ?? '创作者',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentNeon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const CreationWorkspace();
      case 1:
        return _buildProjectsManager();
      case 2:
        return _buildAIModelsManager();
      case 3:
        return _buildSettingsManager();
      default:
        return const CreationWorkspace();
    }
  }

  Widget _buildProjectsManager() {
    return const Center(
      child: Text(
        '作品管理功能开发中...',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAIModelsManager() {
    return const Center(
      child: Text(
        'AI模型管理功能开发中...',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSettingsManager() {
    return const Center(
      child: Text(
        '系统设置功能开发中...',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('您确定要登出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }
}