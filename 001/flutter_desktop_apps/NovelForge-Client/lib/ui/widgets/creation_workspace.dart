import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'glass_panel.dart';
import 'cyber_button.dart';
import 'cyber_text_field.dart';

class CreationWorkspace extends StatefulWidget {
  const CreationWorkspace({super.key});

  @override
  State<CreationWorkspace> createState() => _CreationWorkspaceState();
}

class _CreationWorkspaceState extends State<CreationWorkspace>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final _projectNameController = TextEditingController();
  final _genreController = TextEditingController();
  final _targetWordsController = TextEditingController(text: '100000');
  
  String _selectedStyle = '现代简约';
  double _targetWords = 100000;
  
  final List<String> _styles = [
    '现代简约',
    '古典雅致',
    '激情澎湃',
    '细腻温婉',
  ];
  
  final List<String> _genres = [
    '科幻小说',
    '玄幻小说',
    '都市小说',
    '历史小说',
    '悬疑小说',
  ];
  
  final List<CreationStage> _creationStages = [
    CreationStage(
      id: 'worldview',
      name: '世界观设定',
      icon: Icons.public,
      description: '构建小说的世界观和背景设定',
      status: CreationStageStatus.waiting,
      progress: 0.0,
    ),
    CreationStage(
      id: 'outline',
      name: '故事大纲',
      icon: Icons.map_outlined,
      description: '制定整体故事结构和情节发展',
      status: CreationStageStatus.waiting,
      progress: 0.0,
    ),
    CreationStage(
      id: 'characters',
      name: '人物小传',
      icon: Icons.people_outline,
      description: '创建主要人物的背景和性格特点',
      status: CreationStageStatus.waiting,
      progress: 0.0,
    ),
    CreationStage(
      id: 'style',
      name: '风格指南',
      icon: Icons.palette_outlined,
      description: '确定作品的文学风格和叙述方式',
      status: CreationStageStatus.waiting,
      progress: 0.0,
    ),
    CreationStage(
      id: 'conflict',
      name: '核心冲突',
      icon: Icons.flash_on_outlined,
      description: '设计故事的主要冲突和紧张情节',
      status: CreationStageStatus.waiting,
      progress: 0.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _projectNameController.dispose();
    _genreController.dispose();
    _targetWordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 选项卡
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryNeon.withOpacity(0.3),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryNeon,
              unselectedLabelColor: AppTheme.textSecondary,
              indicator: BoxDecoration(
                color: AppTheme.primaryNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.add_circle_outline),
                  text: '项目创建',
                ),
                Tab(
                  icon: Icon(Icons.timeline),
                  text: '创作流程',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 选项卡内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectCreation(),
                _buildCreationWorkflow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCreation() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 项目信息输入
          GlassPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '项目创建区',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                
                const SizedBox(height: 24),
                
                // 项目名称
                CyberTextField(
                  controller: _projectNameController,
                  label: '项目名称',
                  hintText: '请输入小说名称',
                  prefixIcon: Icons.edit,
                ),
                
                const SizedBox(height: 20),
                
                // 题材选择
                _buildGenreSelector(),
                
                const SizedBox(height: 20),
                
                // 目标字数
                _buildWordCountSlider(),
                
                const SizedBox(height: 20),
                
                // 文风偏好
                _buildStyleSelector(),
                
                const SizedBox(height: 32),
                
                // 开始创作按钮
                SizedBox(
                  width: double.infinity,
                  child: CyberButton(
                    onPressed: _startCreation,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('开始创作'),
                        SizedBox(width: 8),
                        Icon(Icons.rocket_launch, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '题材选择',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Orbitron',
          ),
        ),
        
        const SizedBox(height: 8),
        
        DropdownButtonFormField<String>(
          value: _genres.first,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.primaryNeon.withOpacity(0.3),
              ),
            ),
          ),
          dropdownColor: AppTheme.cardBackground,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textPrimary,
          ),
          items: _genres.map((genre) {
            return DropdownMenuItem(
              value: genre,
              child: Text(genre),
            );
          }).toList(),
          onChanged: (value) {
            // Handle genre change
          },
        ),
      ],
    );
  }

  Widget _buildWordCountSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '目标字数',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Orbitron',
              ),
            ),
            
            Text(
              '${_targetWords.toInt().toString().replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'), 
                (match) => '${match[1]},'
              )} 字',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryNeon,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
          ),
          child: Slider(
            value: _targetWords,
            min: 10000,
            max: 1000000,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _targetWords = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '文风偏好',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            fontFamily: 'Orbitron',
          ),
        ),
        
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _styles.map((style) {
            final isSelected = style == _selectedStyle;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStyle = style;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryNeon.withOpacity(0.1)
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryNeon 
                        : AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  style,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected 
                        ? AppTheme.primaryNeon 
                        : AppTheme.textSecondary,
                    fontWeight: isSelected 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCreationWorkflow() {
    return SingleChildScrollView(
      child: GlassPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '专业创作流程',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                
                const Spacer(),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningNeon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningNeon.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.warningNeon,
                        ),
                      ),
                      
                      const SizedBox(width: 6),
                      
                      Text(
                        '等待启动',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningNeon,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 创作阶段列表
            ...._creationStages.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              final isLast = index == _creationStages.length - 1;
              
              return Column(
                children: [
                  _buildStageItem(stage, index),
                  if (!isLast)
                    _buildStageConnector(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStageItem(CreationStage stage, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStageColor(stage.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // 阶段图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStageColor(stage.status).withOpacity(0.1),
              border: Border.all(
                color: _getStageColor(stage.status),
                width: 2,
              ),
            ),
            child: Icon(
              stage.icon,
              color: _getStageColor(stage.status),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 阶段信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  stage.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 进度条
                LinearProgressIndicator(
                  value: stage.progress,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation(
                    _getStageColor(stage.status),
                  ),
                  minHeight: 3,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 状态指示
          Text(
            _getStageStatusText(stage.status),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getStageColor(stage.status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageConnector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Container(
            width: 2,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
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

  Color _getStageColor(CreationStageStatus status) {
    switch (status) {
      case CreationStageStatus.waiting:
        return AppTheme.textMuted;
      case CreationStageStatus.inProgress:
        return AppTheme.primaryNeon;
      case CreationStageStatus.completed:
        return AppTheme.accentNeon;
      case CreationStageStatus.error:
        return AppTheme.dangerNeon;
    }
  }

  String _getStageStatusText(CreationStageStatus status) {
    switch (status) {
      case CreationStageStatus.waiting:
        return '等待中';
      case CreationStageStatus.inProgress:
        return '进行中';
      case CreationStageStatus.completed:
        return '已完成';
      case CreationStageStatus.error:
        return '错误';
    }
  }

  void _startCreation() {
    // 处理开始创作的逻辑
    if (_projectNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入项目名称'),
          backgroundColor: AppTheme.dangerNeon,
        ),
      );
      return;
    }
    
    // TODO: 实现创作逻辑
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开始创作'),
        content: Text('准备开始创作「${_projectNameController.text}」'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}

// 创作阶段数据类
class CreationStage {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final CreationStageStatus status;
  final double progress;
  
  CreationStage({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.status,
    required this.progress,
  });
}

enum CreationStageStatus {
  waiting,
  inProgress,
  completed,
  error,
}