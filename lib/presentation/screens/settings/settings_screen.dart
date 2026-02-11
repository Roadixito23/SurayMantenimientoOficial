import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/responsive/responsive_builder.dart';
import '../../../models/usuario.dart';
import '../../../services/auth_service.dart';
import '../../../main.dart';
import '../../../presentation/screens/login/login_screen.dart';
import 'layouts/settings_desktop_layout.dart';
import 'layouts/settings_mobile_layout.dart';

// =====================================================================
// === SETTINGS SCREEN - Punto de entrada responsive ===================
// =====================================================================
// Maneja todo el estado, controladores de texto, lógica CRUD de
// usuarios y contraseñas. Delega renderizado al layout correspondiente.

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- CONTROLADORES ---
  final _nombreUsuarioController = TextEditingController();
  final _contrasenaActualController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();
  final _nuevoUsuarioNombreController = TextEditingController();
  final _nuevoUsuarioContrasenaController = TextEditingController();

  // --- ESTADO ---
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureNewUserPassword = true;

  List<Usuario> _usuarios = [];
  bool _isLoadingUsuarios = true;

  @override
  void initState() {
    super.initState();
    if (AuthService.usuarioActual != null) {
      _nombreUsuarioController.text = AuthService.usuarioActual!.nombreUsuario;
    }
    _cargarUsuarios();
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

  // --- CARGA DE DATOS ---
  Future<void> _cargarUsuarios() async {
    setState(() => _isLoadingUsuarios = true);
    try {
      final usuarios = await AuthService.obtenerUsuarios();
      if (mounted) {
        setState(() {
          _usuarios = usuarios;
          _isLoadingUsuarios = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsuarios = false);
    }
  }

  // --- ACCIONES ---
  Future<void> _cambiarNombreUsuario() async {
    if (_nombreUsuarioController.text.trim().isEmpty) {
      _mostrarError('El nombre de usuario no puede estar vacío');
      return;
    }

    final resultado = await AuthService.cambiarNombreUsuario(
        _nombreUsuarioController.text.trim());
    if (resultado) {
      _mostrarExito('Nombre de usuario actualizado correctamente');
    } else {
      _mostrarError('Error al actualizar el nombre de usuario');
    }
  }

  Future<void> _cambiarContrasena() async {
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
    if (_nuevaContrasenaController.text !=
        _confirmarContrasenaController.text) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }

    final resultado = await AuthService.cambiarContrasena(
      _contrasenaActualController.text,
      _nuevaContrasenaController.text,
    );

    if (resultado) {
      _mostrarExito('Contraseña actualizada correctamente');
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
      if (mounted) Navigator.pop(context);
      _cargarUsuarios();
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
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirmar Eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar al usuario "$nombreUsuario"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final resultado = await AuthService.eliminarUsuario(userId);
      if (resultado['success']) {
        _mostrarExito(resultado['message']);
        _cargarUsuarios();
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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: SurayColors.azulMarinoProfundo),
              const SizedBox(width: 8),
              const Text('Crear Nuevo Usuario'),
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
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
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
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewUserPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setDialogState(() {
                          _obscureNewUserPassword = !_obscureNewUserPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _crearNuevoUsuario,
              style: ElevatedButton.styleFrom(
                backgroundColor: SurayColors.azulMarinoProfundo,
              ),
              child: const Text('Crear Usuario'),
            ),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: SurayColors.naranjaQuemado),
            const SizedBox(width: 8),
            const Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuarioActual;

    return ResponsiveBuilder(
      mobile: (context) => SettingsMobileLayout(
        usuario: usuario,
        nombreController: _nombreUsuarioController,
        currentPasswordController: _contrasenaActualController,
        newPasswordController: _nuevaContrasenaController,
        confirmPasswordController: _confirmarContrasenaController,
        obscureCurrent: _obscureCurrentPassword,
        obscureNew: _obscureNewPassword,
        obscureConfirm: _obscureConfirmPassword,
        onToggleCurrent: () =>
            setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
        onToggleNew: () =>
            setState(() => _obscureNewPassword = !_obscureNewPassword),
        onToggleConfirm: () =>
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        onSaveNombre: _cambiarNombreUsuario,
        onSavePassword: _cambiarContrasena,
        onCrearUsuario: _mostrarDialogoCrearUsuario,
        onEliminarUsuario: _eliminarUsuario,
        onCerrarSesion: _cerrarSesion,
        usuarios: _usuarios,
        isLoadingUsuarios: _isLoadingUsuarios,
      ),
      desktop: (context) => SettingsDesktopLayout(
        usuario: usuario,
        nombreController: _nombreUsuarioController,
        currentPasswordController: _contrasenaActualController,
        newPasswordController: _nuevaContrasenaController,
        confirmPasswordController: _confirmarContrasenaController,
        obscureCurrent: _obscureCurrentPassword,
        obscureNew: _obscureNewPassword,
        obscureConfirm: _obscureConfirmPassword,
        onToggleCurrent: () =>
            setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
        onToggleNew: () =>
            setState(() => _obscureNewPassword = !_obscureNewPassword),
        onToggleConfirm: () =>
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        onSaveNombre: _cambiarNombreUsuario,
        onSavePassword: _cambiarContrasena,
        onCrearUsuario: _mostrarDialogoCrearUsuario,
        onEliminarUsuario: _eliminarUsuario,
        onCerrarSesion: _cerrarSesion,
        usuarios: _usuarios,
        isLoadingUsuarios: _isLoadingUsuarios,
      ),
    );
  }
}
