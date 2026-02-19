import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'responsive_utils.dart';

class DuolingoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isGradient;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;

  const DuolingoButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.textWhite,
    this.isGradient = true,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    // Tamaños responsivos
    double buttonHeight;
    double fontSize;
    double borderRadius;
    EdgeInsets padding;
    
    if (isMobile) {
      buttonHeight = isLandscape ? 45.0 : 52.0;
      fontSize = isLandscape ? 14.0 : 16.0;
      borderRadius = 14.0;
      padding = EdgeInsets.symmetric(
        horizontal: isLandscape ? 16.0 : 20.0,
        vertical: isLandscape ? 10.0 : 14.0,
      );
    } else if (ResponsiveUtils.isTablet(context)) {
      buttonHeight = isLandscape ? 50.0 : 56.0;
      fontSize = isLandscape ? 16.0 : 18.0;
      borderRadius = 16.0;
      padding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
    } else {
      buttonHeight = 60.0;
      fontSize = 18.0;
      borderRadius = 18.0;
      padding = EdgeInsets.symmetric(horizontal: 32.0, vertical: 18.0);
    }

    return Container(
      height: buttonHeight,
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: fontSize,
                      height: fontSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOutlined ? backgroundColor : textColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: isOutlined ? backgroundColor : textColor,
                            size: fontSize * 1.1,
                          ),
                          SizedBox(width: isMobile ? 8.0 : 12.0),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isOutlined ? backgroundColor : textColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}