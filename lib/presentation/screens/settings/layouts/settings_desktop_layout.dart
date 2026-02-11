import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../../models/usuario.dart';
import '../../../widgets/settings/settings_widgets.dart';

// =====================================================================
// === SETTINGS DESKTOP LAYOUT ========================================
// =====================================================================
// Vista de escritorio: dos columnas con scroll independiente.
// Columna izquierda: perfil + nombre de usuario.
// Columna derecha: contraseña + gestión de usuarios + cerrar sesión.

class SettingsDesktopLayout extends StatelessWidget {
  final Usuario? usuario;
  final TextEditingController nombreController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSaveNombre;
  final VoidCallback onSavePassword;
  final VoidCallback onCrearUsuario;
  final void Function(String, String) onEliminarUsuario;
  final VoidCallback onCerrarSesion;
  final List<Usuario> usuarios;
  final bool isLoadingUsuarios;

  const SettingsDesktopLayout({
    Key? key,
    required this.usuario,
    required this.nombreController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onSaveNombre,
    required this.onSavePassword,
    required this.onCrearUsuario,
    required this.onEliminarUsuario,
    required this.onCerrarSesion,
    required this.usuarios,
    required this.isLoadingUsuarios,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurayColors.blancoHumo,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: SurayColors.azulMarinoProfundo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Columna izquierda: perfil + nombre ---
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (usuario != null)
                      UserInfoCard(usuario: usuario!),
                    const SizedBox(height: 24),
                    ChangeUsernameCard(
                      controller: nombreController,
                      onSave: onSaveNombre,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // --- Columna derecha: contraseña + usuarios + logout ---
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ChangePasswordCard(
                      currentController: currentPasswordController,
                      newController: newPasswordController,
                      confirmController: confirmPasswordController,
                      obscureCurrent: obscureCurrent,
                      obscureNew: obscureNew,
                      obscureConfirm: obscureConfirm,
                      onToggleCurrent: onToggleCurrent,
                      onToggleNew: onToggleNew,
                      onToggleConfirm: onToggleConfirm,
                      onSave: onSavePassword,
                    ),
                    const SizedBox(height: 24),
                    UserManagementCard(
                      usuarios: usuarios,
                      isLoading: isLoadingUsuarios,
                      onCrearUsuario: onCrearUsuario,
                      onEliminarUsuario: onEliminarUsuario,
                    ),
                    const SizedBox(height: 24),
                    LogoutButton(onPressed: onCerrarSesion),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
