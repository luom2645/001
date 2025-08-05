import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../../core/auth/auth_service.dart';
import 'glass_panel.dart';

class CyberSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  
  const CyberSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  State<CyberSidebar> createState() => _CyberSidebarState();
}

class _CyberSidebarState extends State<CyberSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  final List<SidebarItem> _menuItems = [
    SidebarItem(
      icon: Icons.create,
      activeIcon: Icons.create,
      label: '创作中心',
      color: AppTheme.primaryNeon,
    ),
    SidebarItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      label: '作品管理',
      color: AppTheme.accentNeon,
    ),
    SidebarItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'AI模型',
      color: AppTheme.secondaryNeon,
    ),
    SidebarItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '系统设置',
      color: AppTheme.warningNeon,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 280, 0),
          child: Container(
            width: 280,
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                right: BorderSide(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildMenuItems(),
                ),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  AppTheme.primaryNeon,
                  AppTheme.secondaryNeon,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNeon.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories,
              size: 30,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 应用名称
          Text(
            'NovelForge',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryNeon,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          Text(
            'Client',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 分割线
          Container(
            width: double.infinity,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryNeon.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isSelected = index == widget.selectedIndex;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SidebarMenuItem(
            item: item,
            isSelected: isSelected,
            onTap: () => widget.onItemSelected(index),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 用户信息
          GlassPanel(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                    size: 18,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthService().currentUser?.email?.split('@').first ?? '创作者',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentNeon,
                            ),
                          ),
                          
                          const SizedBox(width: 4),
                          
                          Text(
                            '已认证',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentNeon,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 登出按钮
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(
                Icons.logout,
                size: 16,
                color: AppTheme.dangerNeon,
              ),
              label: Text(
                '登出',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.dangerNeon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final SidebarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _SidebarMenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.1,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (!widget.isSelected) {
          _animationController.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (!widget.isSelected) {
          _animationController.reverse();
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected 
                      ? widget.item.color.withOpacity(0.1)
                      : (_isHovered ? AppTheme.surfaceColor.withOpacity(0.5) : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isSelected ? Border.all(
                    color: widget.item.color.withOpacity(0.5),
                    width: 1,
                  ) : null,
                  boxShadow: widget.isSelected ? [
                    BoxShadow(
                      color: widget.item.color.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                      color: widget.isSelected 
                          ? widget.item.color
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.isSelected 
                              ? widget.item.color
                              : AppTheme.textSecondary,
                          fontWeight: widget.isSelected 
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    
                    if (widget.isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.item.color,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  
  SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}