import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/buses/buses_screen.dart';
import '../presentation/screens/repuestos/repuestos_screen.dart';
import '../presentation/screens/reportes/reportes_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../main.dart'; // Para acceder a SurayColors
import '../core/utils/responsive_helper.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isRailExtended = true;
  late AnimationController _animationController;
  double _zoomLevel = 1.0; // Nivel de zoom (1.0 = 100%)

  final List<Widget> _screens = [
    DashboardScreen(),
    BusesScreen(),
    RepuestosScreen(),
    HistorialGlobalScreen(),
  ];

  final List<String> _titles = [
    'Panel Principal',
    'Gestión de Flota',
    'Repuestos',
    'Reportes Diarios',
  ];

  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.directions_bus,
    Icons.build,
    Icons.description,
  ];

  final List<String> _shortcuts = [
    'Alt+1',
    'Alt+2',
    'Alt+3',
    'Alt+4',
  ];

  final List<String> _descriptions = [
    'Resumen general del sistema',
    'Gestión completa de la flota',
    'Inventario y catálogo de repuestos',
    'Reportes diarios de taller',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1):
            () => _navigateTo(0),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2):
            () => _navigateTo(1),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3):
            () => _navigateTo(2),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit4):
            () => _navigateTo(3),
        LogicalKeySet(LogicalKeyboardKey.f5): () => _refreshCurrentScreen(),
        LogicalKeySet(LogicalKeyboardKey.escape): () =>
            _showShortcutsDialog(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: SurayColors.blancoHumo,
          // Drawer para móvil
          drawer: isMobile ? _buildDrawer() : null,
          body: Column(
            children: [
              // Barra superior personalizada
              _buildTopAppBar(isMobile),

              // Breadcrumbs (solo desktop)
              if (!isMobile) _buildBreadcrumbs(),

              // Contenido principal con navegación adaptativa
              Expanded(
                child: Row(
                  children: [
                    // NavigationRail para desktop
                    if (!isMobile) ...[
                      _buildNavigationRail(),
                      VerticalDivider(thickness: 1, width: 1),
                    ],

                    // Área de contenido
                    Expanded(
                      child: Transform.scale(
                        scale: _zoomLevel,
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: SurayColors.blancoHumo,
                          child: Column(
                            children: [
                              // Barra de herramientas contextual (solo desktop)
                              if (!isMobile) _buildContextualToolbar(),

                              // Contenido de la pantalla
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: Offset(0.1, 0.0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    key: ValueKey(_selectedIndex),
                                    child: _screens[_selectedIndex],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Barra de estado (solo desktop)
              if (!isMobile) _buildStatusBar(),
            ],
          ),
          // BottomNavigationBar para móvil
          bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,
        ),
      ),
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SurayColors.azulMarinoProfundo, SurayColors.azulMarinoClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SurayColors.azulMarinoProfundo.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón de menú (solo para desktop - toggle sidebar)
          if (!isMobile)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isRailExtended = !_isRailExtended;
                  });
                },
                child: Container(
                  width: 60,
                  child: Icon(
                    _isRailExtended ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Espaciado en móvil donde estaba el botón de menú
          if (isMobile) SizedBox(width: 16),

          // Logo y título
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SurayColors.naranjaQuemado,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: SurayColors.naranjaQuemado.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(Icons.directions_bus,
                      color: SurayColors.blancoHumo, size: 24),
                ),
                SizedBox(width: 12),
                // Título (mostrar versión compacta en móvil)
                if (isMobile)
                  Text(
                    'Suray',
                    style: TextStyle(
                      color: SurayColors.blancoHumo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sistema de Gestión de Buses',
                        style: TextStyle(
                          color: SurayColors.blancoHumo,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Suray',
                            style: TextStyle(
                              color: SurayColors.naranjaQuemadoClaro,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' • ${_titles[_selectedIndex]}',
                            style: TextStyle(
                              color: SurayColors.blancoHumo.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Herramientas de la barra superior (solo desktop o elementos esenciales en móvil)
          Row(
            children: [
              // Controles de zoom (solo desktop)
              if (!isMobile) ...[
                _buildTopBarButton(
                  icon: Icons.remove,
                  tooltip:
                      'Reducir zoom (${(_zoomLevel * 100).toStringAsFixed(0)}%)',
                  onPressed: _zoomOut,
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: _resetZoom,
                  child: Tooltip(
                    message: 'Restablecer zoom (100%)',
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(_zoomLevel * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                _buildTopBarButton(
                  icon: Icons.add,
                  tooltip:
                      'Ampliar zoom (${(_zoomLevel * 100).toStringAsFixed(0)}%)',
                  onPressed: _zoomIn,
                ),
                SizedBox(width: 16),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(width: 16),
              ],

              // Botones de acción (siempre visibles)
              _buildTopBarButton(
                icon: Icons.refresh,
                tooltip: 'Actualizar (F5)',
                onPressed: _refreshCurrentScreen,
              ),

              if (!isMobile) ...[
                SizedBox(width: 8),
                _buildTopBarButton(
                  icon: Icons.help_outline,
                  tooltip: 'Atajos de teclado (Esc)',
                  onPressed: _showShortcutsDialog,
                ),
                SizedBox(width: 8),
                _buildTopBarButton(
                  icon: Icons.settings,
                  tooltip: 'Configuración',
                  onPressed: _showSettings,
                ),
              ],

              SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    String? badge,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(_icons[_selectedIndex],
              size: 16, color: SurayColors.azulMarinoProfundo),
          SizedBox(width: 8),
          Text(
            _titles[_selectedIndex],
            style: TextStyle(
              color: SurayColors.azulMarinoProfundo,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          Spacer(),

          // Badge de versión
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SurayColors.naranjaQuemado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SurayColors.naranjaQuemado.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'v3.02',
              style: TextStyle(
                color: SurayColors.naranjaQuemado,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(width: 16),

          // Información adicional
          Icon(Icons.access_time,
              size: 14, color: SurayColors.grisAntracitaClaro),
          SizedBox(width: 6),
          Text(
            'Última actualización: ${DateTime.now().toLocal().toString().substring(11, 16)}',
            style:
                TextStyle(color: SurayColors.grisAntracitaClaro, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _isRailExtended ? 280 : 80,
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: 16),

          // Enlaces de navegación
          Expanded(
            child: ListView.builder(
              itemCount: _titles.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? SurayColors.azulMarinoProfundo.withOpacity(0.1)
                        : Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigateTo(index),
                      splashColor: SurayColors.naranjaQuemado.withOpacity(0.2),
                      highlightColor:
                          SurayColors.naranjaQuemado.withOpacity(0.1),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? SurayColors.azulMarinoProfundo
                                    : SurayColors.grisAntracita
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: SurayColors.azulMarinoProfundo
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                _icons[index],
                                color: isSelected
                                    ? SurayColors.blancoHumo
                                    : SurayColors.grisAntracita,
                                size: 20,
                              ),
                            ),
                            if (_isRailExtended) ...[
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _titles[index],
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? SurayColors.azulMarinoProfundo
                                            : SurayColors.grisAntracita,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      _descriptions[index],
                                      style: TextStyle(
                                        color: SurayColors.grisAntracitaClaro,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? SurayColors.naranjaQuemado
                                          .withOpacity(0.1)
                                      : SurayColors.grisAntracita
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? SurayColors.naranjaQuemado
                                            .withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _shortcuts[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? SurayColors.naranjaQuemado
                                        : SurayColors.grisAntracita,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Información del sistema
          if (_isRailExtended) ...[
            Divider(
                height: 1, color: SurayColors.grisAntracita.withOpacity(0.2)),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SurayColors.azulMarinoProfundo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: SurayColors.azulMarinoProfundo),
                      SizedBox(width: 6),
                      Text(
                        'Sistema v3.02',
                        style: TextStyle(
                          fontSize: 12,
                          color: SurayColors.azulMarinoProfundo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Conectado a Firebase',
                        style: TextStyle(
                          fontSize: 10,
                          color: SurayColors.grisAntracita,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContextualToolbar() {
    return Container(
      height: 50,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Título de la sección actual
          Text(
            _titles[_selectedIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: SurayColors.azulMarinoProfundo,
        boxShadow: [
          BoxShadow(
            color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green),
          SizedBox(width: 6),
          Text(
            'Listo',
            style: TextStyle(
                fontSize: 12,
                color: SurayColors.blancoHumo,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 16),
          Container(
              width: 1,
              height: 16,
              color: SurayColors.blancoHumo.withOpacity(0.3)),
          SizedBox(width: 16),
          Icon(Icons.cloud_done, size: 14, color: Colors.green),
          SizedBox(width: 6),
          Text(
            'Conectado a Firebase',
            style: TextStyle(fontSize: 12, color: SurayColors.blancoHumo),
          ),
          Spacer(),
          Icon(Icons.keyboard,
              size: 14, color: SurayColors.naranjaQuemadoClaro),
          SizedBox(width: 6),
          Text(
            'Presiona Esc para ver atajos',
            style: TextStyle(
                fontSize: 12, color: SurayColors.blancoHumo.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  void _navigateTo(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _refreshCurrentScreen() {
    // Trigger refresh en la pantalla actual
    setState(() {});
  }

  void _zoomIn() {
    setState(() {
      if (_zoomLevel < 1.5) {
        _zoomLevel += 0.1;
      }
    });
  }

  void _zoomOut() {
    setState(() {
      if (_zoomLevel > 0.7) {
        _zoomLevel -= 0.1;
      }
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.keyboard, color: SurayColors.azulMarinoProfundo),
            SizedBox(width: 8),
            Text('Atajos de Teclado'),
          ],
        ),
        content: Container(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShortcutRow('Alt + 1', 'Panel Principal'),
              _buildShortcutRow('Alt + 2', 'Gestión de Flota'),
              _buildShortcutRow('Alt + 3', 'Repuestos'),
              _buildShortcutRow('Alt + 4', 'Reportes'),
              Divider(),
              _buildShortcutRow('F5', 'Actualizar pantalla'),
              _buildShortcutRow('Esc', 'Mostrar esta ayuda'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String shortcut, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    // Navegar a la pantalla de Settings
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    ).then((_) {
      // Refrescar la pantalla cuando se regrese
      setState(() {});
    });
  }

  // Drawer para pantallas pequeñas
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SurayColors.azulMarinoProfundo,
                    SurayColors.azulMarinoClaro,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SurayColors.naranjaQuemado,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.directions_bus,
                        color: Colors.white, size: 32),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Gestión de Buses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Suray v3.02',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_titles.length, (index) {
              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == index
                        ? SurayColors.azulMarinoProfundo
                        : SurayColors.grisAntracita.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _icons[index],
                    color: _selectedIndex == index
                        ? Colors.white
                        : SurayColors.grisAntracita,
                  ),
                ),
                title: Text(
                  _titles[index],
                  style: TextStyle(
                    fontWeight: _selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedIndex == index
                        ? SurayColors.azulMarinoProfundo
                        : SurayColors.grisAntracita,
                  ),
                ),
                subtitle: Text(
                  _descriptions[index],
                  style: TextStyle(fontSize: 12),
                ),
                selected: _selectedIndex == index,
                onTap: () {
                  _navigateTo(index);
                  Navigator.pop(context);
                },
              );
            }),
            Divider(),
            ListTile(
              leading:
                  Icon(Icons.settings, color: SurayColors.azulMarinoProfundo),
              title: Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                _showSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  // BottomNavigationBar para pantallas muy pequeñas
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _navigateTo,
      type: BottomNavigationBarType.fixed,
      backgroundColor: SurayColors.azulMarinoProfundo,
      selectedItemColor: SurayColors.naranjaQuemado,
      unselectedItemColor: Colors.white70,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      selectedIconTheme: IconThemeData(size: 26),
      unselectedIconTheme: IconThemeData(size: 22),
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      items: List.generate(_titles.length, (index) {
        return BottomNavigationBarItem(
          icon: Icon(_icons[index]),
          label: _titles[index],
          tooltip: _descriptions[index],
        );
      }),
    );
  }
}
