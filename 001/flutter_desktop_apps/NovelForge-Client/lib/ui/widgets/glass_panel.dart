import 'dart:ui';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final bool enableGlow;
  final Color? glowColor;
  
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blurRadius = 10.0,
    this.boxShadow,
    this.gradient,
    this.enableGlow = true,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppTheme.primaryNeon.withOpacity(0.3);
    final effectiveGlowColor = glowColor ?? AppTheme.primaryNeon;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? (enableGlow ? [
          BoxShadow(
            color: effectiveGlowColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ] : null),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurRadius,
            sigmaY: blurRadius,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor?.withOpacity(0.1) ?? AppTheme.cardBackground.withOpacity(0.1),
                  backgroundColor?.withOpacity(0.05) ?? AppTheme.surfaceColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 带发光效果的玻璃面板
class GlowingGlassPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color glowColor;
  final double glowIntensity;
  final Duration animationDuration;
  
  const GlowingGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.glowColor = AppTheme.primaryNeon,
    this.glowIntensity = 0.3,
    this.animationDuration = const Duration(seconds: 2),
  });

  @override
  State<GlowingGlassPanel> createState() => _GlowingGlassPanelState();
}

class _GlowingGlassPanelState extends State<GlowingGlassPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: widget.glowIntensity * 0.5,
      end: widget.glowIntensity,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GlassPanel(
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: widget.borderRadius,
          backgroundColor: widget.backgroundColor,
          borderColor: widget.glowColor.withOpacity(_glowAnimation.value),
          glowColor: widget.glowColor,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withOpacity(_glowAnimation.value),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
          child: widget.child,
        );
      },
    );
  }
}

/// 数据流动画背景面板
class DataFlowPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color flowColor;
  final double flowSpeed;
  
  const DataFlowPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.flowColor = AppTheme.primaryNeon,
    this.flowSpeed = 1.0,
  });

  @override
  State<DataFlowPanel> createState() => _DataFlowPanelState();
}

class _DataFlowPanelState extends State<DataFlowPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: (3000 / widget.flowSpeed).round()),
      vsync: this,
    );
    
    _flowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景数据流
        AnimatedBuilder(
          animation: _flowAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: DataFlowPainter(
                _flowAnimation.value,
                widget.flowColor,
                widget.borderRadius,
              ),
            );
          },
        ),
        
        // 主要内容
        GlassPanel(
          padding: widget.padding,
          margin: widget.margin,
          borderRadius: widget.borderRadius,
          backgroundColor: widget.backgroundColor,
          child: widget.child,
        ),
      ],
    );
  }
}

/// 数据流动画绘制器
class DataFlowPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double borderRadius;
  
  DataFlowPainter(this.animation, this.color, this.borderRadius);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // 绘制流动线条
    for (int i = 0; i < 5; i++) {
      final y = (i * size.height / 5) + (animation * size.height / 2) % size.height;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y);
      
      canvas.drawPath(path, paint);
    }
    
    // 绘制竖直线条
    for (int i = 0; i < 8; i++) {
      final x = (i * size.width / 8) + (animation * size.width / 4) % size.width;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x, size.height);
      
      canvas.drawPath(path, paint..color = color.withOpacity(0.05));
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}