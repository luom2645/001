import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../themes/app_theme.dart';
import '../../core/auth/auth_service.dart';
import '../../utils/constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _particleAnimationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _particleAnimation;
  
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _logoAnimationController.forward();
    _particleAnimationController.repeat();
  }

  Future<void> _initializeApp() async {
    try {
      // 初始化认证服务
      await AuthService().initialize();
      
      // 显示加载动画
      await Future.delayed(AppConstants.splashDuration);
      
      setState(() {
        _isInitialized = true;
      });
      
      // 检查用户登录状态
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        final authService = AuthService();
        if (authService.isAuthenticated && authService.isDeviceBound) {
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      }
    } catch (e) {
      debugPrint('应用初始化失败: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _particleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: Stack(
          children: [
            // 背景粒子效果
            _buildParticleBackground(),
            
            // 主要内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 动画
                  _buildAnimatedLogo(),
                  
                  const SizedBox(height: 40),
                  
                  // 应用名称动画
                  _buildAppNameAnimation(),
                  
                  const SizedBox(height: 20),
                  
                  // 描述文本
                  Text(
                    AppConstants.appDescription,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // 加载指示器
                  _buildLoadingIndicator(),
                ],
              ),
            ),
            
            // 底部信息
            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height),
          painter: ParticlesPainter(_particleAnimation.value),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Container(
            width: 120,
            height: 120,
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
                  color: AppTheme.primaryNeon.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories,
              size: 60,
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppNameAnimation() {
    return AnimatedTextKit(
      animatedTexts: [
        TypewriterAnimatedText(
          'NovelForge Client',
          textStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppTheme.primaryNeon,
            fontWeight: FontWeight.bold,
          ),
          speed: const Duration(milliseconds: 100),
        ),
      ],
      totalRepeatCount: 1,
      pause: const Duration(milliseconds: 1000),
      displayFullTextOnTap: true,
      stopPauseOnTap: true,
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryNeon,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isInitialized ? '初始化完成' : '正在初始化...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            '版本 ${AppConstants.appVersion}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by MiniMax Agent',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// 粒子效果绘制器
class ParticlesPainter extends CustomPainter {
  final double animation;
  
  ParticlesPainter(this.animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryNeon.withOpacity(0.1)
      ..strokeWidth = 1.0;
    
    // 绘制粒子效果
    for (int i = 0; i < 50; i++) {
      final x = (i * 37.0 + animation * 100) % size.width;
      final y = (i * 23.0 + animation * 50) % size.height;
      final radius = (i % 3) + 1.0;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}