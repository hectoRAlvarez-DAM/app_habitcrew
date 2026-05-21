import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'responsive_utils.dart';

class DuolingoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;

  const DuolingoTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);

    // Tamaños responsivos
    double fontSize;
    double labelFontSize;
    double iconSize;
    double borderRadius;
    EdgeInsets contentPadding;

    if (isMobile) {
      fontSize = isLandscape ? 14.0 : 16.0;
      labelFontSize = isLandscape ? 12.0 : 14.0;
      iconSize = isLandscape ? 18.0 : 20.0;
      borderRadius = 12.0;
      contentPadding = EdgeInsets.symmetric(
        horizontal: isLandscape ? 12.0 : 16.0,
        vertical: isLandscape ? 10.0 : 14.0,
      );
    } else if (ResponsiveUtils.isTablet(context)) {
      fontSize = isLandscape ? 16.0 : 18.0;
      labelFontSize = 14.0;
      iconSize = 22.0;
      borderRadius = 14.0;
      contentPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
    } else {
      fontSize = 18.0;
      labelFontSize = 16.0;
      iconSize = 24.0;
      borderRadius = 16.0;
      contentPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label con color visible
        Text(
          labelText,
          style: TextStyle(
            color: Colors.white,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6.0),

        // Campo de texto con colores visibles
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            enabled: enabled,
            focusNode: focusNode,
            onFieldSubmitted: onSubmitted,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white54, fontSize: fontSize),
              filled: true,
              fillColor: Colors.transparent,
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: isMobile ? 12.0 : 16.0,
                        right: isMobile ? 8.0 : 12.0,
                      ),
                      child: Icon(
                        prefixIcon,
                        color: enabled
                            ? const Color(0xFF58CC02)
                            : Colors.white38,
                        size: iconSize,
                      ),
                    )
                  : null,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.primary, width: 2.0),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              contentPadding: contentPadding,
            ),
          ),
        ),
      ],
    );
  }
}
