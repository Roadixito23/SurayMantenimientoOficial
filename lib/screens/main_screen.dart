import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'buses_screen.dart';
import 'repuestos_screen.dart';
import 'reportes_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isRailExtended = true;
  late AnimationController _animationController;

  final List<Widget> _screens = [
    DashboardScreen(),
    BusesScreen(),
    RepuestosScreen(),
    HistorialGlobalScreen(),
  ];

  final List<String> _titles = [
    'Panel Principal',
    'Gestión de Buses',
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
    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1): () => _navigateTo(0),
          LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2): () => _navigateTo(1),
          LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3): () => _navigateTo(2),
          LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit4): () => _navigateTo(3),
          LogicalKeySet(LogicalKeyboardKey.f5): () => _refreshCurrentScreen(),
          LogicalKeySet(LogicalKeyboardKey.escape): () => _showShortcutsDialog(),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              // Barra superior mejorada
              _buildTopAppBar(),

              // Breadcrumbs
              _buildBreadcrumbs(),

              // Contenido principal
              Expanded(
                child: Row(
                  children: [
                    // Navegación lateral expandible
                    _buildNavigationRail(),

                    // Divisor
                    VerticalDivider(thickness: 1, width: 1),

                    // Área de contenido principal
                    Expanded(
                      child: Container(
                        color: Colors.grey[50],
                        child: Column(
                          children: [
                            // Barra de herramientas contextual
                            _buildContextualToolbar(),

                            // Contenido de la pantalla
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
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
                  ],
                ),
              ),

              // Barra de estado
              _buildStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Color(0xFF1565C0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón para contraer/expandir navegación
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

          // Logo y título
          Expanded(
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema de Gestión de Buses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Suray - ${_titles[_selectedIndex]}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Herramientas de la barra superior
          Row(
            children: [
              // Búsqueda global
              Container(
                width: 250,
                height: 35,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar globalmente... (Ctrl+K)',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),

              SizedBox(width: 16),

              // Botones de acción
              _buildTopBarButton(
                icon: Icons.refresh,
                tooltip: 'Actualizar (F5)',
                onPressed: _refreshCurrentScreen,
              ),

              _buildTopBarButton(
                icon: Icons.help_outline,
                tooltip: 'Atajos de teclado (Esc)',
                onPressed: _showShortcutsDialog,
              ),

              _buildTopBarButton(
                icon: Icons.settings,
                tooltip: 'Configuración',
                onPressed: _showSettings,
              ),

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
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.home, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            'Inicio',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
          SizedBox(width: 8),
          Text(
            _titles[_selectedIndex],
            style: TextStyle(
              color: Color(0xFF1565C0),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          Spacer(),

          // Información adicional
          Text(
            'Última actualización: ${DateTime.now().toLocal().toString().substring(11, 16)}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                    color: isSelected ? Color(0xFF1565C0).withOpacity(0.1) : Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigateTo(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF1565C0) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _icons[index],
                                color: isSelected ? Colors.white : Colors.grey[600],
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
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Color(0xFF1565C0) : Colors.grey[800],
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      _descriptions[index],
                                      style: TextStyle(
                                        color: Colors.grey[600],
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
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _shortcuts[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
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
            Divider(height: 1),
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistema v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Conectado a Firebase',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[600],
                    ),
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

  Widget _buildContextButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 1,
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 24,
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Listo',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),

          SizedBox(width: 16),

          Text(
            'Estado: Conectado',
            style: TextStyle(fontSize: 12, color: Colors.green[600]),
          ),

          Spacer(),

          Text(
            'Presiona Esc para ver atajos',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  void _triggerScreenAction(String action) {
    // Implementar acciones específicas por pantalla
    print('Acción triggereada: $action en pantalla $_selectedIndex');
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Notificaciones'),
          ],
        ),
        content: Container(
          width: 400,
          height: 300,
          child: ListView(
            children: [
              _buildNotificationTile(
                icon: Icons.warning,
                title: 'Buses con revisión técnica vencida',
                subtitle: '2 buses requieren atención inmediata',
                time: 'Hace 5 min',
                color: Colors.red,
              ),
              _buildNotificationTile(
                icon: Icons.build,
                title: 'Repuestos próximos a vencer',
                subtitle: '3 repuestos requieren cambio pronto',
                time: 'Hace 1 hora',
                color: Colors.orange,
              ),
              _buildNotificationTile(
                icon: Icons.check_circle,
                title: 'Mantenimiento completado',
                subtitle: 'Bus AB-CD-12 listo para servicio',
                time: 'Hace 2 horas',
                color: Colors.green,
              ),
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

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: Text(time, style: TextStyle(fontSize: 11, color: Colors.grey)),
      dense: true,
    );
  }

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.keyboard, color: Color(0xFF1565C0)),
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
              _buildShortcutRow('Alt + 2', 'Gestión de Buses'),
              _buildShortcutRow('Alt + 3', 'Repuestos'),
              _buildShortcutRow('Alt + 4', 'Reportes'),
              Divider(),
              _buildShortcutRow('F5', 'Actualizar pantalla'),
              _buildShortcutRow('Ctrl + K', 'Búsqueda global'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Configuración'),
          ],
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Navegación extendida'),
                subtitle: Text('Mostrar descripciones en el menú lateral'),
                value: _isRailExtended,
                onChanged: (value) {
                  setState(() {
                    _isRailExtended = value;
                  });
                  Navigator.pop(context);
                },
              ),
              SwitchListTile(
                title: Text('Animaciones'),
                subtitle: Text('Efectos de transición entre pantallas'),
                value: true,
                onChanged: (value) {},
              ),
              SwitchListTile(
                title: Text('Notificaciones'),
                subtitle: Text('Alertas del sistema'),
                value: true,
                onChanged: (value) {},
              ),
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
}