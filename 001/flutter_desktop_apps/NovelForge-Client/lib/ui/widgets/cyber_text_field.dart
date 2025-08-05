import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class CyberTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextStyle? style;
  final double borderRadius;
  
  const CyberTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.style,
    this.borderRadius = 8.0,
  });

  @override
  State<CyberTextField> createState() => _CyberTextFieldState();
}

class _CyberTextFieldState extends State<CyberTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
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

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });
    
    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  Color get _borderColor {
    if (_hasError) return AppTheme.dangerNeon;
    if (_isFocused) return AppTheme.primaryNeon;
    return AppTheme.primaryNeon.withOpacity(0.3);
  }
  
  Color get _glowColor {
    if (_hasError) return AppTheme.dangerNeon;
    return AppTheme.primaryNeon;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _isFocused ? [
              BoxShadow(
                color: _glowColor.withOpacity(_glowAnimation.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label != null) ...
              [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.label!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isFocused ? AppTheme.primaryNeon : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ],
              Focus(
                onFocusChange: _handleFocusChange,
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  style: widget.style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: widget.enabled ? AppTheme.textPrimary : AppTheme.textMuted,
                    fontFamily: 'RobotoMono',
                  ),
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onSubmitted,
                  validator: (value) {
                    final error = widget.validator?.call(value);
                    setState(() {
                      _hasError = error != null;
                      _errorText = error;
                    });
                    return error;
                  },
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: _isFocused ? AppTheme.primaryNeon : AppTheme.textSecondary,
                          )
                        : null,
                    suffixIcon: widget.suffixIcon,
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: _borderColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: _borderColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: const BorderSide(
                        color: AppTheme.dangerNeon,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: const BorderSide(
                        color: AppTheme.dangerNeon,
                        width: 2,
                      ),
                    ),
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontFamily: 'RobotoMono',
                    ),
                    errorStyle: const TextStyle(
                      color: AppTheme.dangerNeon,
                      fontSize: 12,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}