import 'package:flutter/material.dart';
import 'app_colors.dart';

class DuolingoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isGradient;
  final bool isOutlined;
  final double borderRadius;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool isLoading;

  const DuolingoButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.textWhite,
    this.isGradient = true,
    this.isOutlined = false,
    this.borderRadius = 16.0,
    this.elevation = 4.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
    this.fontSize = 18.0,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      elevation: elevation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: isGradient && !isOutlined ? AppColors.buttonGradient : null,
          color: isOutlined ? Colors.transparent : 
                (isGradient ? null : backgroundColor),
          border: isOutlined 
              ? Border.all(color: backgroundColor, width: 2.0)
              : null,
          boxShadow: isOutlined ? null : [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: MaterialButton(
          onPressed: isLoading ? null : onPressed,
          minWidth: double.infinity,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: isLoading
              ? SizedBox(
                  height: 24.0,
                  width: 24.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOutlined ? backgroundColor : textColor,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: isOutlined ? backgroundColor : textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}