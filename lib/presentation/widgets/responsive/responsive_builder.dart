import 'package:flutter/material.dart';
import '../../../core/utils/responsive_helper.dart';

// =====================================================================
// === RESPONSIVE BUILDER WIDGET =======================================
// =====================================================================
// Widget que construye diferentes layouts según el tamaño de pantalla
// 
// Uso básico:
// ```dart
// ResponsiveBuilder(
//   mobile: (context) => MobileLayout(),
//   desktop: (context) => DesktopLayout(),
// )
// ```
//
// Uso con tablet:
// ```dart
// ResponsiveBuilder(
//   mobile: (context) => MobileLayout(),
//   tablet: (context) => TabletLayout(), // Opcional
//   desktop: (context) => DesktopLayout(),
// )
// ```

/// Tipo de función builder que recibe el contexto y retorna un Widget
typedef ResponsiveWidgetBuilder = Widget Function(BuildContext context);

/// Widget que construye layouts diferentes según el tamaño de pantalla
class ResponsiveBuilder extends StatelessWidget {
  /// Builder para layout móvil (< 600px)
  final ResponsiveWidgetBuilder mobile;

  /// Builder para layout tablet (600px - 899px) - Opcional
  /// Si no se provee, se usa el layout móvil
  final ResponsiveWidgetBuilder? tablet;

  /// Builder para layout desktop (>= 900px)
  final ResponsiveWidgetBuilder desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: >= 900px
        if (ResponsiveHelper.isDesktop(context)) {
          return desktop(context);
        }
        
        // Tablet: 600px - 899px (si se provee)
        if (ResponsiveHelper.isTablet(context) && tablet != null) {
          return tablet!(context);
        }
        
        // Mobile: < 600px (o tablet sin builder específico)
        return mobile(context);
      },
    );
  }
}

// =====================================================================
// === RESPONSIVE LAYOUT (Simplificado) ================================
// =====================================================================
// Versión alternativa que acepta Widgets directos en lugar de builders

/// Widget responsivo que acepta widgets directos
class ResponsiveLayout extends StatelessWidget {
  /// Widget para layout móvil
  final Widget mobile;

  /// Widget para layout tablet (opcional)
  final Widget? tablet;

  /// Widget para layout desktop
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => mobile,
      tablet: tablet != null ? (_) => tablet! : null,
      desktop: (_) => desktop,
    );
  }
}

// =====================================================================
// === RESPONSIVE VALUE WIDGET =========================================
// =====================================================================
// Widget que retorna un valor específico según el tamaño de pantalla

/// Widget genérico que retorna valores diferentes según el tamaño de pantalla
class ResponsiveValue<T> extends StatelessWidget {
  /// Valor para móvil
  final T mobile;

  /// Valor para tablet (opcional, usa mobile si no se provee)
  final T? tablet;

  /// Valor para desktop
  final T desktop;

  /// Builder que usa el valor resuelto
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveHelper.responsiveValue<T>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );

    return builder(context, value);
  }
}
