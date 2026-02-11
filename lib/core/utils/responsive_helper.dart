import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

// =====================================================================
// === RESPONSIVE HELPER - Utilidades para diseño adaptativo ==========
// =====================================================================
// Proporciona métodos útiles para implementar diseños responsive

/// Clase helper con métodos estáticos para facilitar diseños responsive
class ResponsiveHelper {
  // ===================================================================
  // === MÉTODOS DE DETECCIÓN DE TIPO DE DISPOSITIVO ==================
  // ===================================================================
  
  /// Determina si el ancho actual corresponde a un dispositivo móvil
  /// Retorna true si width < 600px
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }
  
  /// Determina si el ancho actual corresponde a un dispositivo móvil pequeño
  /// Retorna true si width < 360px
  static bool isMobileSmall(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobileSmall;
  }
  
  /// Determina si el ancho actual corresponde a una tablet
  /// Retorna true si 600px <= width < 900px
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }
  
  /// Determina si el ancho actual corresponde a desktop
  /// Retorna true si width >= 900px
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }
  
  /// Determina si el ancho actual corresponde a desktop grande
  /// Retorna true si width >= 1200px
  static bool isDesktopLarge(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktopLarge;
  }
  
  /// Obtiene el tipo de dispositivo actual basado en el ancho de pantalla
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < Breakpoints.mobileSmall) {
      return DeviceType.mobileSmall;
    } else if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.desktop) {
      return DeviceType.tablet;
    } else if (width < Breakpoints.desktopLarge) {
      return DeviceType.desktop;
    } else {
      return DeviceType.desktopLarge;
    }
  }
  
  // ===================================================================
  // === MÉTODOS DE VALORES RESPONSIVE =================================
  // ===================================================================
  
  /// Retorna un valor diferente según el tipo de dispositivo
  /// 
  /// Ejemplo:
  /// ```dart
  /// final fontSize = ResponsiveHelper.responsiveValue(
  ///   context,
  ///   mobile: 14.0,
  ///   tablet: 16.0,
  ///   desktop: 18.0,
  /// );
  /// ```
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
  
  /// Retorna un valor específico según el ancho de pantalla
  /// Útil cuando necesitas más control que los breakpoints estándar
  static T valueWhen<T>({
    required BuildContext context,
    T? mobileSmall,
    required T mobile,
    T? tablet,
    required T desktop,
    T? desktopLarge,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= Breakpoints.desktopLarge && desktopLarge != null) {
      return desktopLarge;
    } else if (width >= Breakpoints.desktop) {
      return desktop;
    } else if (width >= Breakpoints.mobile && tablet != null) {
      return tablet;
    } else if (width < Breakpoints.mobileSmall && mobileSmall != null) {
      return mobileSmall;
    } else {
      return mobile;
    }
  }
  
  // ===================================================================
  // === MÉTODOS PARA LAYOUTS ==========================================
  // ===================================================================
  
  /// Retorna el número de columnas apropiado para un grid según el dispositivo
  /// 
  /// Por defecto:
  /// - Mobile: 1 columna
  /// - Tablet: 2 columnas
  /// - Desktop: 3 columnas
  /// 
  /// Puedes personalizar con los parámetros opcionales
  static int gridColumns(
    BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    return responsiveValue(
      context: context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );
  }
  
  /// Retorna el padding horizontal apropiado según el dispositivo
  /// 
  /// Por defecto:
  /// - Mobile: 16px
  /// - Tablet: 24px
  /// - Desktop: 32px
  static double horizontalPadding(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }
  
  /// Retorna el padding vertical apropiado según el dispositivo
  /// 
  /// Por defecto:
  /// - Mobile: 16px
  /// - Tablet: 20px
  /// - Desktop: 24px
  static double verticalPadding(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
  }
  
  /// Retorna EdgeInsets responsive para padding general
  static EdgeInsets screenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: verticalPadding(context),
    );
  }
  
  /// Retorna el ancho máximo para contenido centrado
  /// Útil para evitar que el contenido se expanda demasiado en pantallas grandes
  /// 
  /// Por defecto:
  /// - Mobile: ancho completo
  /// - Tablet: 700px
  /// - Desktop: 1200px
  static double maxContentWidth(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 700,
      desktop: 1200,
    );
  }
  
  /// Retorna el tamaño de fuente base según el dispositivo
  static double baseFontSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );
  }
  
  /// Retorna el tamaño de título según el dispositivo
  static double titleFontSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );
  }
  
  /// Retorna el tamaño de heading según el dispositivo
  static double headingFontSize(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
  }
  
  // ===================================================================
  // === MÉTODOS PARA COMPONENTES ESPECÍFICOS ==========================
  // ===================================================================
  
  /// Retorna el ancho apropiado para un dialog según el dispositivo
  static double dialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile(context)) {
      return screenWidth * 0.9; // 90% del ancho en mobile
    } else if (isTablet(context)) {
      return 500; // Ancho fijo en tablet
    } else {
      return 600; // Ancho fijo en desktop
    }
  }
  
  /// Determina si se debe usar un dialog fullscreen (mobile) o normal (desktop)
  static bool useFullscreenDialog(BuildContext context) {
    return isMobile(context);
  }
  
  /// Retorna el alto del AppBar según el dispositivo
  static double appBarHeight(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 56.0,
      tablet: 64.0,
      desktop: 64.0,
    );
  }
  
  /// Retorna el ancho del NavigationRail en desktop
  static double navigationRailWidth({bool extended = false}) {
    return extended ? 200.0 : 72.0;
  }
  
  /// Retorna el alto del BottomNavigationBar en mobile
  static double bottomNavigationBarHeight() {
    return 60.0;
  }
  
  // ===================================================================
  // === MÉTODOS DE ORIENTACIÓN ========================================
  // ===================================================================
  
  /// Determina si el dispositivo está en orientación portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// Determina si el dispositivo está en orientación landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  // ===================================================================
  // === MÉTODOS ÚTILES ADICIONALES ====================================
  // ===================================================================
  
  /// Obtiene el ancho de la pantalla
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Obtiene el alto de la pantalla
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Calcula un porcentaje del ancho de la pantalla
  static double percentWidth(BuildContext context, double percent) {
    return screenWidth(context) * (percent / 100);
  }
  
  /// Calcula un porcentaje del alto de la pantalla
  static double percentHeight(BuildContext context, double percent) {
    return screenHeight(context) * (percent / 100);
  }
}
