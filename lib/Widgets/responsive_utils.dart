import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Tamaños de breakpoint
  static const double mobileWidth = 600;
  static const double tabletWidth = 900;
  static const double desktopWidth = 1200;

  // Determinar tipo de dispositivo
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobileWidth;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobileWidth && 
      MediaQuery.of(context).size.width < tabletWidth;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= tabletWidth;
  
  static bool isLandscape(BuildContext context) => 
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Obtener dimensiones escaladas
  static double getResponsiveWidth(BuildContext context, 
      {double mobile = 100, double tablet = 150, double desktop = 200}) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileWidth) return mobile;
    if (width < tabletWidth) return tablet;
    return desktop;
  }

  static double getResponsiveHeight(BuildContext context, 
      {double mobile = 50, double tablet = 60, double desktop = 70}) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    
    // Para landscape, usar el ancho como referencia
    if (isLandscape(context)) {
      if (width < mobileWidth) return mobile;
      if (width < tabletWidth) return tablet;
      return desktop;
    }
    
    // Para portrait, usar el alto
    if (height < 600) return mobile;
    if (height < 800) return tablet;
    return desktop;
  }

  static double getResponsiveFontSize(BuildContext context,
      {double mobile = 14, double tablet = 16, double desktop = 18}) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileWidth) return mobile;
    if (width < tabletWidth) return tablet;
    return desktop;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  static double getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }
}