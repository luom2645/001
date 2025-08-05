import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'glass_panel.dart';
import 'cyber_button.dart';
import 'cyber_text_field.dart';

class AIAssistantPanel extends StatefulWidget {
  final VoidCallback onClose;
  
  const AIAssistantPanel({
    super.key,
    required this.onClose,
  });

  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      content: '你好！我是AI创作助手，可以帮助你进行小说创作。请问你想创作什么类型的作品？',
      isFromUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  
  bool _isTyping = false;
  String _selectedModel = 'GPT-4';
  
  final List<String> _models = ['GPT-4', 'Claude', 'Gemini'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          border: Border(
            left: BorderSide(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildChatArea(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryNeon,
                      AppTheme.secondaryNeon,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 18,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Text(
                  'AI创作助手',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 模型选择
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryNeon.withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedModel,
                isDense: true,
                dropdownColor: AppTheme.cardBackground,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
                items: _models.map((model) {
                  return DropdownMenuItem(
                    value: model,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getModelColor(model),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(model),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedModel = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return GlassPanel(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // 正在输入指示
          if (_isTyping)
            _buildTypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromUser) ..[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getModelColor(_selectedModel),
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isFromUser 
                    ? AppTheme.primaryNeon.withOpacity(0.1)
                    : AppTheme.surfaceColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: message.isFromUser 
                      ? AppTheme.primaryNeon.withOpacity(0.3)
                      : AppTheme.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isFromUser) ..[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryNeon,
              ),
              child: const Icon(
                Icons.person,
                size: 14,
                color: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getModelColor(_selectedModel),
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 14,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(width: 8),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI正在思考',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryNeon,
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

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CyberTextField(
              controller: _messageController,
              hintText: '输入你的问题...',
              maxLines: 3,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          SizedBox(
            width: 40,
            height: 40,
            child: CyberButton(
              onPressed: _isTyping ? null : _sendMessage,
              padding: EdgeInsets.zero,
              borderRadius: 20,
              child: const Icon(
                Icons.send,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getModelColor(String model) {
    switch (model) {
      case 'GPT-4':
        return AppTheme.primaryNeon;
      case 'Claude':
        return AppTheme.secondaryNeon;
      case 'Gemini':
        return AppTheme.accentNeon;
      default:
        return AppTheme.textMuted;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isFromUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // 模拟AI响应
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.add(ChatMessage(
          content: '感谢你的提问！这是一个模拟AI回复，在实际应用中，这里会连接到真API进行智能对话。',
          isFromUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class ChatMessage {
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.content,
    required this.isFromUser,
    required this.timestamp,
  });
}