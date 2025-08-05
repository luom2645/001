import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../themes/app_theme.dart';
import '../../core/auth/auth_service.dart';
import '../widgets/cyber_button.dart';
import '../widgets/cyber_text_field.dart';
import '../widgets/glass_panel.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = AuthService();
      late AuthResult result;
      
      if (_isLogin) {
        result = await authService.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        result = await authService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }
      
      if (result.success) {
        if (_isLogin && mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          _showSuccessMessage(result.message);
          if (!_isLogin) {
            setState(() {
              _isLogin = true;
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '发生未知错误，请重试';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentNeon,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildAuthForm(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: GlassPanel(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildFormFields(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 16),
                _buildToggleAuth(),
                if (_errorMessage != null) ...
                  _buildErrorMessage(),
                const SizedBox(height: 24),
                _buildSecurityInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
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
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.security,
            size: 40,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              _isLogin ? '欢迎回来' : '创建账户',
              textStyle: Theme.of(context).textTheme.headlineLarge,
              speed: const Duration(milliseconds: 100),
            ),
          ],
          totalRepeatCount: 1,
          key: ValueKey(_isLogin),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? '登录您的AI小说创作工具' : '加入AI小说创作之旅',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        if (!_isLogin)
          CyberTextField(
            controller: _nameController,
            label: '姓名',
            prefixIcon: Icons.person,
            validator: (value) {
              if (!_isLogin) return null;
              if (value == null || value.isEmpty) {
                return '请输入姓名';
              }
              return null;
            },
          ),
        if (!_isLogin) const SizedBox(height: 16),
        CyberTextField(
          controller: _emailController,
          label: '邮箱地址',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入邮箱地址';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return '请输入有效的邮箱地址';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CyberTextField(
          controller: _passwordController,
          label: '密码',
          prefixIcon: Icons.lock,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入密码';
            }
            if (value.length < 6) {
              return '密码至少需要6位字符';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CyberButton(
        onPressed: _isLoading ? null : _handleSubmit,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(_isLogin ? '登录' : '注册'),
      ),
    );
  }

  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? '没有账户？' : '已有账户？',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: _toggleAuthMode,
          child: Text(
            _isLogin ? '立即注册' : '立即登录',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryNeon,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildErrorMessage() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.dangerNeon.withOpacity(0.1),
          border: Border.all(
            color: AppTheme.dangerNeon.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.dangerNeon,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.dangerNeon,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNeon.withOpacity(0.05),
        border: Border.all(
          color: AppTheme.primaryNeon.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shield,
                color: AppTheme.primaryNeon,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '设备绑定安全',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryNeon,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '您的账户将与当前设备进行安全绑定，确保只有您才能访问您的创作内容。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}