import 'package:flutter/material.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../main.dart'; // Para SurayColors

// =====================================================================
// === ADAPTIVE SCAFFOLD ===============================================
// =====================================================================
// Scaffold adaptativo que cambia entre:
// - Mobile: BottomNavigationBar
// - Desktop: NavigationRail lateral
//
// Uso:
// ```dart
// AdaptiveScaffold(
//   currentIndex: _selectedIndex,
//   destinations: [
//     NavigationDestination(
//       icon: Icon(Icons.dashboard),
//       label: 'Dashboard',
//     ),
//     // ...
//   ],
//   onDestinationSelected: (index) => setState(() => _selectedIndex = index),
//   body: _screens[_selectedIndex],
//   title: _titles[_selectedIndex],
// )
// ```

/// Item de navegación para AdaptiveScaffold
class NavigationDestination {
  /// Icono del item
  final Icon icon;

  /// Icono cuando está seleccionado (opcional)
  final Icon? selectedIcon;

  /// Texto/label del item
  final String label;

  /// Descripción (tooltip) del item
  final String? tooltip;

  /// Badge (contador de notificaciones) - opcional
  final Widget? badge;

  const NavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.badge,
  });
}

/// Scaffold adaptativo que cambia navegación según el dispositivo
class AdaptiveScaffold extends StatefulWidget {
  /// Índice del destino actualmente seleccionado
  final int currentIndex;

  /// Lista de destinos de navegación
  final List<NavigationDestination> destinations;

  /// Callback cuando se selecciona un destino
  final ValueChanged<int> onDestinationSelected;

  /// Cuerpo principal del scaffold
  final Widget body;

  /// Título mostrado en el AppBar (opcional)
  final String? title;

  /// AppBar personalizado (opcional, sobrescribe title)
  final PreferredSizeWidget? appBar;

  /// FloatingActionButton (opcional)
  final Widget? floatingActionButton;

  /// Widget en el drawer (opcional)
  final Widget? drawer;

  /// Widget en el endDrawer (opcional)
  final Widget? endDrawer;

  /// Si el NavigationRail debe mostrar labels en desktop
  final bool extendedRail;

  /// Ancho del NavigationRail cuando está extendido
  final double extendedRailWidth;

  /// Color de fondo del scaffold
  final Color? backgroundColor;

  const AdaptiveScaffold({
    Key? key,
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.body,
    this.title,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.extendedRail = true,
    this.extendedRailWidth = 200.0,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? SurayColors.blancoHumo,
      appBar: widget.appBar ?? (widget.title != null ? _buildAppBar() : null),
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      body: isMobile ? _buildMobileBody() : _buildDesktopBody(),
      bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  /// Construye el AppBar por defecto
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.title ?? ''),
      elevation: 0,
      backgroundColor: SurayColors.azulMarinoProfundo,
      foregroundColor: Colors.white,
    );
  }

  /// Construye el body para móvil (solo el contenido)
  Widget _buildMobileBody() {
    return SafeArea(
      child: widget.body,
    );
  }

  /// Construye el body para desktop (NavigationRail + contenido)
  Widget _buildDesktopBody() {
    return Row(
      children: [
        // NavigationRail lateral
        NavigationRail(
          extended: widget.extendedRail,
          minExtendedWidth: widget.extendedRailWidth,
          backgroundColor: SurayColors.azulMarinoProfundo,
          selectedIndex: widget.currentIndex,
          onDestinationSelected: widget.onDestinationSelected,
          labelType: widget.extendedRail
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
          selectedIconTheme: IconThemeData(
            color: SurayColors.naranjaQuemado,
            size: 28,
          ),
          unselectedIconTheme: IconThemeData(
            color: Colors.white70,
            size: 24,
          ),
          selectedLabelTextStyle: TextStyle(
            color: SurayColors.naranjaQuemado,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
          indicatorColor: SurayColors.naranjaQuemado.withOpacity(0.2),
          destinations: widget.destinations.map((dest) {
            return NavigationRailDestination(
              icon: dest.badge != null
                  ? Badge(
                      label: dest.badge,
                      child: dest.icon,
                    )
                  : dest.icon,
              selectedIcon: dest.selectedIcon ?? dest.icon,
              label: Text(dest.label),
            );
          }).toList(),
        ),

        // Divisor vertical
        VerticalDivider(
          thickness: 1,
          width: 1,
          color: Colors.grey[300],
        ),

        // Contenido principal
        Expanded(
          child: widget.body,
        ),
      ],
    );
  }

  /// Construye el BottomNavigationBar para móvil
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onDestinationSelected,
      type: BottomNavigationBarType.fixed,
      backgroundColor: SurayColors.azulMarinoProfundo,
      selectedItemColor: SurayColors.naranjaQuemado,
      unselectedItemColor: Colors.white70,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 11,
      ),
      selectedIconTheme: IconThemeData(
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
      ),
      items: widget.destinations.map((dest) {
        return BottomNavigationBarItem(
          icon: dest.badge != null
              ? Badge(
                  label: dest.badge,
                  child: dest.icon,
                )
              : dest.icon,
          activeIcon: dest.selectedIcon ?? dest.icon,
          label: dest.label,
          tooltip: dest.tooltip ?? dest.label,
        );
      }).toList(),
    );
  }
}

// =====================================================================
// === SIMPLE ADAPTIVE SCAFFOLD ========================================
// =====================================================================
// Versión simplificada sin navegación, solo con layout adaptativo

/// Scaffold adaptativo simple sin navegación
class SimpleAdaptiveScaffold extends StatelessWidget {
  /// Título del AppBar
  final String? title;

  /// AppBar personalizado
  final PreferredSizeWidget? appBar;

  /// Cuerpo del scaffold
  final Widget body;

  /// FloatingActionButton
  final Widget? floatingActionButton;

  /// Drawer
  final Widget? drawer;

  /// Color de fondo
  final Color? backgroundColor;

  /// Si debe aplicar SafeArea en móvil
  final bool applySafeArea;

  const SimpleAdaptiveScaffold({
    Key? key,
    this.title,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
    this.applySafeArea = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    Widget content = body;
    if (isMobile && applySafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? SurayColors.blancoHumo,
      appBar: appBar ?? (title != null ? AppBar(title: Text(title!)) : null),
      drawer: drawer,
      body: content,
      floatingActionButton: floatingActionButton,
    );
  }
}
