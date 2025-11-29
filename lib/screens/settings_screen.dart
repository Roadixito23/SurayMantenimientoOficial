import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nombreUsuarioController = TextEditingController();
  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  // Controladores para crear nuevo usuario
  final _nuevoUsuarioNombreController = TextEditingController();
  final _nuevoUsuarioContrasenaController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureNewUserPassword = true;

  @override
  void initState() {
    super.initState();
    // Cargar nombre de usuario actual
    if (AuthService.usuarioActual != null) {
      _nombreUsuarioController.text = AuthService.usuarioActual!.nombreUsuario;
    }
  }

  @override
  void dispose() {
    _nombreUsuarioController.dispose();
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    _nuevoUsuarioNombreController.dispose();
    _nuevoUsuarioContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _cambiarNombreUsuario() async {
    if (_nombreUsuarioController.text.trim().isEmpty) {
      _mostrarError('El nombre de usuario no puede estar vacío');
      return;
    }

    final resultado = await AuthService.cambiarNombreUsuario(_nombreUsuarioController.text.trim());

    if (resultado) {
      _mostrarExito('Nombre de usuario actualizado correctamente');
    } else {
      _mostrarError('Error al actualizar el nombre de usuario');
    }
  }

  Future<void> _cambiarContrasena() async {
    // Validaciones
    if (_contrasenaActualController.text.isEmpty ||
        _nuevaContrasenaController.text.isEmpty ||
        _confirmarContrasenaController.text.isEmpty) {
      _mostrarError('Todos los campos son obligatorios');
      return;
    }

    if (_nuevaContrasenaController.text.length != 8) {
      _mostrarError('La nueva contraseña debe tener 8 dígitos');
      return;
    }

    if (_nuevaContrasenaController.text != _confirmarContrasenaController.text) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }

    final resultado = await AuthService.cambiarContrasena(
      _contrasenaActualController.text,
      _nuevaContrasenaController.text,
    );

    if (resultado) {
      _mostrarExito('Contraseña actualizada correctamente');
      // Limpiar campos
      _contrasenaActualController.clear();
      _nuevaContrasenaController.clear();
      _confirmarContrasenaController.clear();
    } else {
      _mostrarError('Contraseña actual incorrecta');
    }
  }

  Future<void> _crearNuevoUsuario() async {
    if (_nuevoUsuarioNombreController.text.trim().isEmpty ||
        _nuevoUsuarioContrasenaController.text.isEmpty) {
      _mostrarError('Todos los campos son obligatorios');
      return;
    }

    if (_nuevoUsuarioContrasenaController.text.length != 8) {
      _mostrarError('La contraseña debe tener 8 dígitos');
      return;
    }

    final resultado = await AuthService.crearUsuario(
      nombreUsuario: _nuevoUsuarioNombreController.text.trim(),
      contrasena: _nuevoUsuarioContrasenaController.text,
    );

    if (resultado['success']) {
      _mostrarExito(resultado['message']);
      _nuevoUsuarioNombreController.clear();
      _nuevoUsuarioContrasenaController.clear();
      setState(() {}); // Refrescar la lista de usuarios
      Navigator.pop(context); // Cerrar el diálogo
    } else {
      _mostrarError(resultado['message']);
    }
  }

  Future<void> _eliminarUsuario(String userId, String nombreUsuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar al usuario "$nombreUsuario"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final resultado = await AuthService.eliminarUsuario(userId);
      if (resultado['success']) {
        _mostrarExito(resultado['message']);
        setState(() {}); // Refrescar la lista
      } else {
        _mostrarError(resultado['message']);
      }
    }
  }

  void _mostrarDialogoCrearUsuario() {
    _nuevoUsuarioNombreController.clear();
    _nuevoUsuarioContrasenaController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: SurayColors.azulMarinoProfundo),
            SizedBox(width: 8),
            Text('Crear Nuevo Usuario'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nuevoUsuarioNombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nuevoUsuarioContrasenaController,
                obscureText: _obscureNewUserPassword,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  labelText: 'Contraseña (8 dígitos)',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewUserPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewUserPassword = !_obscureNewUserPassword;
                      });
                      // Forzar rebuild del diálogo
                      Navigator.pop(context);
                      _mostrarDialogoCrearUsuario();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _crearNuevoUsuario,
            style: ElevatedButton.styleFrom(
              backgroundColor: SurayColors.azulMarinoProfundo,
            ),
            child: Text('Crear Usuario'),
          ),
        ],
      ),
    );
  }

  Future<void> _migrarContrasenas() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Text('Migrar Contraseñas'),
          ],
        ),
        content: Text(
          '¿Deseas migrar todas las contraseñas a formato encriptado?\n\n'
          'Esta operación convertirá todas las contraseñas en texto plano a hashes seguros usando bcrypt.\n\n'
          'Solo necesitas hacer esto UNA VEZ.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text('Migrar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Migrando contraseñas...'),
            ],
          ),
        ),
      );

      final resultado = await AuthService.migrarContrasenasAHash();

      // Cerrar diálogo de carga
      Navigator.pop(context);

      if (resultado['success']) {
        _mostrarExito(resultado['message']);
      } else {
        _mostrarError(resultado['message']);
      }
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: SurayColors.naranjaQuemado),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SurayColors.naranjaQuemado,
            ),
            child: Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: SurayColors.blancoHumo,
      appBar: AppBar(
        title: Text('Configuración'),
        backgroundColor: SurayColors.azulMarinoProfundo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          children: [
            // Información del usuario actual
            _buildUserInfoCard(),
            SizedBox(height: 24),

            // Sección: Cambiar nombre de usuario
            _buildChangeUsernameCard(),
            SizedBox(height: 24),

            // Sección: Cambiar contraseña
            _buildChangePasswordCard(),
            SizedBox(height: 24),

            // Sección: Gestión de usuarios
            _buildUserManagementCard(),
            SizedBox(height: 24),

            // Botón de cerrar sesión
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final usuario = AuthService.usuarioActual;
    if (usuario == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SurayColors.azulMarinoProfundo,
                    SurayColors.azulMarinoClaro,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SurayColors.azulMarinoProfundo.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // Nombre de usuario
            Text(
              usuario.nombreUsuario,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SurayColors.azulMarinoProfundo,
              ),
            ),
            SizedBox(height: 8),

            // Fecha de creación
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SurayColors.naranjaQuemado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SurayColors.naranjaQuemado.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: SurayColors.naranjaQuemado,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Miembro desde ${_formatDate(usuario.fechaCreacion)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: SurayColors.naranjaQuemado,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeUsernameCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: SurayColors.azulMarinoProfundo,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Cambiar Nombre de Usuario',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SurayColors.azulMarinoProfundo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            TextField(
              controller: _nombreUsuarioController,
              decoration: InputDecoration(
                labelText: 'Nuevo nombre de usuario',
                prefixIcon: Icon(Icons.person, color: SurayColors.azulMarinoProfundo),
                filled: true,
                fillColor: SurayColors.blancoHumo,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SurayColors.azulMarinoProfundo, width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _cambiarNombreUsuario,
                icon: Icon(Icons.save),
                label: Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SurayColors.azulMarinoProfundo,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SurayColors.naranjaQuemado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock,
                    color: SurayColors.naranjaQuemado,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Cambiar Contraseña',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SurayColors.azulMarinoProfundo,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Contraseña actual
            _buildPasswordField(
              controller: _contrasenaActualController,
              label: 'Contraseña actual',
              obscure: _obscureCurrentPassword,
              onToggle: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
            ),
            SizedBox(height: 16),

            // Nueva contraseña
            _buildPasswordField(
              controller: _nuevaContrasenaController,
              label: 'Nueva contraseña (8 dígitos)',
              obscure: _obscureNewPassword,
              onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            SizedBox(height: 16),

            // Confirmar contraseña
            _buildPasswordField(
              controller: _confirmarContrasenaController,
              label: 'Confirmar nueva contraseña',
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _cambiarContrasena,
                icon: Icon(Icons.lock_reset),
                label: Text('Cambiar Contraseña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SurayColors.naranjaQuemado,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: SurayColors.azulMarinoProfundo),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: SurayColors.grisAntracita,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: SurayColors.blancoHumo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: SurayColors.azulMarinoProfundo, width: 2),
        ),
      ),
    );
  }

  Widget _buildUserManagementCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people,
                        color: SurayColors.azulMarinoProfundo,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Gestión de Usuarios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SurayColors.azulMarinoProfundo,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _mostrarDialogoCrearUsuario,
                  icon: Icon(Icons.person_add, color: SurayColors.naranjaQuemado),
                  tooltip: 'Crear nuevo usuario',
                  style: IconButton.styleFrom(
                    backgroundColor: SurayColors.naranjaQuemado.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Lista de usuarios
            FutureBuilder(
              future: AuthService.obtenerUsuarios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Error al cargar usuarios',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final usuarios = snapshot.data ?? [];

                if (usuarios.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No hay usuarios registrados',
                        style: TextStyle(color: SurayColors.grisAntracita),
                      ),
                    ),
                  );
                }

                return Column(
                  children: usuarios.map((usuario) {
                    final esUsuarioActual = usuario.id == AuthService.usuarioActual?.id;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: esUsuarioActual
                            ? SurayColors.naranjaQuemado.withOpacity(0.1)
                            : SurayColors.blancoHumo,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esUsuarioActual
                              ? SurayColors.naranjaQuemado.withOpacity(0.3)
                              : SurayColors.grisAntracita.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: esUsuarioActual
                                ? SurayColors.naranjaQuemado
                                : SurayColors.azulMarinoProfundo,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                usuario.nombreUsuario,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: SurayColors.azulMarinoProfundo,
                                ),
                              ),
                            ),
                            if (esUsuarioActual)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: SurayColors.naranjaQuemado,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Tú',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Creado: ${_formatDate(usuario.fechaCreacion)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: SurayColors.grisAntracita,
                          ),
                        ),
                        trailing: !esUsuarioActual
                            ? IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarUsuario(
                                  usuario.id,
                                  usuario.nombreUsuario,
                                ),
                                tooltip: 'Eliminar usuario',
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            SizedBox(height: 16),

            // Botón para crear usuario
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _mostrarDialogoCrearUsuario,
                icon: Icon(Icons.person_add),
                label: Text('Crear Nuevo Usuario'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SurayColors.azulMarinoProfundo,
                  side: BorderSide(color: SurayColors.azulMarinoProfundo, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Botón para migrar contraseñas
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _migrarContrasenas,
                icon: Icon(Icons.security),
                label: Text('Migrar Contraseñas a Bcrypt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _cerrarSesion,
        icon: Icon(Icons.logout),
        label: Text('Cerrar Sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }
}
