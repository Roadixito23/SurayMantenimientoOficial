// =====================================================================
// === BREAKPOINTS RESPONSIVOS - Sistema Suray =========================
// =====================================================================
// Define los puntos de quiebre para diseños responsive
// Siguiendo Material Design guidelines y mejores prácticas

/// Clase que define los breakpoints responsive de la aplicación
class Breakpoints {
  // Breakpoints principales
  
  /// Dispositivos móviles pequeños (< 360px)
  /// Ej: iPhone SE, smartphones antiguos
  static const double mobileSmall = 360;
  
  /// Dispositivos móviles estándar (< 480px)
  /// Ej: iPhone 12/13, Samsung Galaxy S20
  static const double mobileLarge = 480;
  
  /// Limite superior para móviles (< 600px)
  /// Por encima de esto se considera tablet
  static const double mobile = 600;
  
  /// Dispositivos tablet (600px - 899px)
  /// Ej: iPad Mini, tablets Android
  static const double tablet = 900;
  
  /// Dispositivos desktop (>= 900px)
  /// Laptops, monitores de escritorio
  static const double desktop = 900;
  
  /// Pantallas grandes (>= 1200px)
  /// Monitores grandes, pantallas 4K
  static const double desktopLarge = 1200;
  
  /// Pantallas extra grandes (>= 1600px)
  /// Monitores ultra anchos
  static const double desktopXL = 1600;
  
  // Breakpoints adicionales útiles
  
  /// Límite para transición mobile -> tablet
  static const double mobileToTablet = 600;
  
  /// Límite para transición tablet -> desktop
  static const double tabletToDesktop = 900;
}

/// Enumeración para tipos de dispositivos
enum DeviceType {
  /// Móvil pequeño (< 360px)
  mobileSmall,
  
  /// Móvil estándar (360px - 600px)
  mobile,
  
  /// Tablet (600px - 900px)
  tablet,
  
  /// Desktop (900px - 1200px)
  desktop,
  
  /// Desktop grande (>= 1200px)
  desktopLarge,
}
