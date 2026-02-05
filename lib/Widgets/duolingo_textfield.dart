import 'package:flutter/material.dart';
import 'app_colors.dart';

class DuolingoTextField extends StatefulWidget {
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
  final bool autoFocus;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const DuolingoTextField({
    Key? key,
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
    this.autoFocus = false,
    this.textInputAction,
    this.onSubmitted,
  }) : super(key: key);

  @override
  _DuolingoTextFieldState createState() => _DuolingoTextFieldState();
}

class _DuolingoTextFieldState extends State<DuolingoTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label con animación
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            widget.labelText,
            style: TextStyle(
              color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        const SizedBox(height: 8.0),
        
        // Campo de texto con efectos
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: _isFocused ? AppColors.cardGradient : null,
            color: !_isFocused ? AppColors.backgroundGrey : null,
            boxShadow: _isFocused ? AppColors.softShadow : [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
            border: _isFocused ? Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2.0,
            ) : null,
          ),
          child: Focus(
            onFocusChange: (focused) {
              setState(() {
                _isFocused = focused;
              });
            },
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onChanged: widget.onChanged,
              enabled: widget.enabled,
              autofocus: widget.autoFocus,
              textInputAction: widget.textInputAction,
              onFieldSubmitted: widget.onSubmitted,
              style: TextStyle(
                color: widget.enabled ? AppColors.textPrimary : AppColors.textLight,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.transparent,
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                        child: Icon(
                          widget.prefixIcon,
                          color: _isFocused ? AppColors.primary : AppColors.textLight,
                          size: 22.0,
                        ),
                      )
                    : null,
                suffixIcon: widget.suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(
                    color: AppColors.error,
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 18.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}