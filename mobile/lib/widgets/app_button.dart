import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/app_dimens.dart';
import '../theme/app_animations.dart';

enum AppButtonStyle { filled, outlined, text, gradient }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double? height;
  final Color? color;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.filled,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height,
    this.color,
    this.textColor,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();
  void _onTapUp(TapUpDetails _) => _scaleController.reverse();
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.accent1;
    final effectiveTextColor = widget.textColor ?? Colors.white;
    final effectiveHeight = widget.height ?? AppDimens.buttonHeight;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: widget.onPressed != null ? _onTapCancel : null,
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          width: widget.fullWidth ? double.infinity : null,
          height: effectiveHeight,
          decoration: _buildDecoration(effectiveColor),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.loading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              child: Center(
                child: _buildContent(effectiveColor, effectiveTextColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(Color effectiveColor) {
    switch (widget.style) {
      case AppButtonStyle.filled:
        return BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: 0.3),
              blurRadius: AppDimens.shadowMd,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppButtonStyle.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: effectiveColor, width: 1.5),
        );
      case AppButtonStyle.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        );
      case AppButtonStyle.gradient:
        return BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent1.withValues(alpha: 0.3),
              blurRadius: AppDimens.shadowMd,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  Widget _buildContent(Color effectiveColor, Color effectiveTextColor) {
    if (widget.loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: widget.style == AppButtonStyle.outlined
              ? effectiveColor
              : Colors.white,
        ),
      );
    }

    final children = <Widget>[];
    if (widget.icon != null) {
      children.add(Icon(widget.icon, size: AppDimens.iconMd, color: effectiveTextColor));
      children.add(const SizedBox(width: AppSpacing.sm));
    }
    children.add(
      Text(
        widget.label,
        style: TextStyle(
          color: widget.style == AppButtonStyle.outlined
              ? effectiveColor
              : effectiveTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
