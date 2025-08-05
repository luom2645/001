import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class CyberButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final bool isSecondary;
  final bool isDanger;
  final bool isOutlined;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  
  const CyberButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.isSecondary = false,
    this.isDanger = false,
    this.isOutlined = false,
    this.padding,
    this.borderRadius = 8.0,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
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

  Color get _buttonColor {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    if (widget.isDanger) return AppTheme.dangerNeon;
    if (widget.isSecondary) return AppTheme.secondaryNeon;
    return AppTheme.primaryNeon;
  }
  
  Color get _textColor {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    if (widget.isOutlined) return _buttonColor;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
          widget.onPressed?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height ?? 48,
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isOutlined ? Colors.transparent : _buttonColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: _buttonColor,
                    width: widget.isOutlined ? 2 : 1,
                  ),
                  boxShadow: widget.onPressed == null ? null : [
                    BoxShadow(
                      color: _buttonColor.withOpacity(_glowAnimation.value),
                      blurRadius: _isHovered ? 12 : 6,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                  gradient: widget.isOutlined || widget.onPressed == null ? null : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _buttonColor,
                      _buttonColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: widget.onPressed == null 
                          ? AppTheme.textMuted 
                          : _textColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Orbitron',
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}