import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../../models/usuario.dart';
import '../../../widgets/settings/settings_widgets.dart';

// =====================================================================
// === SETTINGS MOBILE LAYOUT =========================================
// =====================================================================
// Vista móvil: scroll vertical con header compacto de perfil,
// secciones colapsables para nombre/contraseña/usuarios, y botón de
// cerrar sesión al final con padding inferior para BottomNavigationBar.

class SettingsMobileLayout extends StatelessWidget {
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

  const SettingsMobileLayout({
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
      body: Column(
        children: [
          // --- Header compacto con info de usuario ---
          if (usuario != null)
            UserInfoCard(usuario: usuario!, compact: true),

          // --- Contenido scrolleable ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
              child: Column(
                children: [
                  // Nombre de usuario
                  ChangeUsernameCard(
                    controller: nombreController,
                    onSave: onSaveNombre,
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
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
                  const SizedBox(height: 16),

                  // Gestión de usuarios
                  UserManagementCard(
                    usuarios: usuarios,
                    isLoading: isLoadingUsuarios,
                    onCrearUsuario: onCrearUsuario,
                    onEliminarUsuario: onEliminarUsuario,
                  ),
                  const SizedBox(height: 20),

                  // Cerrar sesión
                  LogoutButton(onPressed: onCerrarSesion, compact: true),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
