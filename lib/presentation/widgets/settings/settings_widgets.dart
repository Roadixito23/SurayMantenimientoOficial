import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../main.dart';
import '../../../models/usuario.dart';
import '../../../services/auth_service.dart';

// =====================================================================
// === SETTINGS WIDGETS - Componentes compartidos ======================
// =====================================================================

// --- Sección de cabecera para cada card de configuración ---

class SettingsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Widget? trailing;

  const SettingsSectionHeader({
    Key? key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? SurayColors.azulMarinoProfundo;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SurayColors.azulMarinoProfundo,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// --- Campo de contraseña reutilizable ---

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const PasswordField({
    Key? key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        prefixIcon:
            Icon(Icons.lock_outline, color: SurayColors.azulMarinoProfundo),
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
          borderSide:
              BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: SurayColors.azulMarinoProfundo, width: 2),
        ),
      ),
    );
  }
}

// --- Card de información del usuario ---

class UserInfoCard extends StatelessWidget {
  final Usuario usuario;
  final bool compact;

  const UserInfoCard({
    Key? key,
    required this.usuario,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(16),
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
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              usuario.nombreUsuario,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SurayColors.azulMarinoProfundo,
              ),
            ),
            const SizedBox(height: 8),
            _buildFechaCreacionBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SurayColors.azulMarinoProfundo,
            SurayColors.azulMarinoProfundo.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreUsuario,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Miembro desde ${formatDate(usuario.fechaCreacion)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
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

  Widget _buildFechaCreacionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SurayColors.naranjaQuemado.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SurayColors.naranjaQuemado.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today,
              size: 14, color: SurayColors.naranjaQuemado),
          const SizedBox(width: 6),
          Text(
            'Miembro desde ${formatDate(usuario.fechaCreacion)}',
            style: TextStyle(
              fontSize: 12,
              color: SurayColors.naranjaQuemado,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Card de cambiar nombre de usuario ---

class ChangeUsernameCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const ChangeUsernameCard({
    Key? key,
    required this.controller,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsSectionHeader(
              icon: Icons.edit,
              title: 'Cambiar Nombre de Usuario',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nuevo nombre de usuario',
                prefixIcon: Icon(Icons.person,
                    color: SurayColors.azulMarinoProfundo),
                filled: true,
                fillColor: SurayColors.blancoHumo,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: SurayColors.grisAntracita.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: SurayColors.grisAntracita.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: SurayColors.azulMarinoProfundo, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SurayColors.azulMarinoProfundo,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Card de cambiar contraseña ---

class ChangePasswordCard extends StatelessWidget {
  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSave;

  const ChangePasswordCard({
    Key? key,
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(
              icon: Icons.lock,
              title: 'Cambiar Contraseña',
              iconColor: SurayColors.naranjaQuemado,
            ),
            const SizedBox(height: 20),
            PasswordField(
              controller: currentController,
              label: 'Contraseña actual',
              obscure: obscureCurrent,
              onToggle: onToggleCurrent,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: newController,
              label: 'Nueva contraseña (8 dígitos)',
              obscure: obscureNew,
              onToggle: onToggleNew,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: confirmController,
              label: 'Confirmar nueva contraseña',
              obscure: obscureConfirm,
              onToggle: onToggleConfirm,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Cambiar Contraseña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SurayColors.naranjaQuemado,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Card de gestión de usuarios ---

class UserManagementCard extends StatelessWidget {
  final List<Usuario> usuarios;
  final bool isLoading;
  final VoidCallback onCrearUsuario;
  final void Function(String userId, String nombre) onEliminarUsuario;

  const UserManagementCard({
    Key? key,
    required this.usuarios,
    required this.isLoading,
    required this.onCrearUsuario,
    required this.onEliminarUsuario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(
              icon: Icons.people,
              title: 'Gestión de Usuarios',
              trailing: IconButton(
                onPressed: onCrearUsuario,
                icon:
                    Icon(Icons.person_add, color: SurayColors.naranjaQuemado),
                tooltip: 'Crear nuevo usuario',
                style: IconButton.styleFrom(
                  backgroundColor:
                      SurayColors.naranjaQuemado.withOpacity(0.1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildUserList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onCrearUsuario,
                icon: const Icon(Icons.person_add),
                label: const Text('Crear Nuevo Usuario'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SurayColors.azulMarinoProfundo,
                  side: BorderSide(
                      color: SurayColors.azulMarinoProfundo, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (usuarios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No hay usuarios registrados',
            style: TextStyle(color: SurayColors.grisAntracita),
          ),
        ),
      );
    }

    return Column(
      children: usuarios.map((usuario) {
        final esActual = usuario.id == AuthService.usuarioActual?.id;
        return UsuarioListTile(
          usuario: usuario,
          esActual: esActual,
          onEliminar: esActual
              ? null
              : () => onEliminarUsuario(usuario.id, usuario.nombreUsuario),
        );
      }).toList(),
    );
  }
}

// --- Tile de usuario individual ---

class UsuarioListTile extends StatelessWidget {
  final Usuario usuario;
  final bool esActual;
  final VoidCallback? onEliminar;

  const UsuarioListTile({
    Key? key,
    required this.usuario,
    required this.esActual,
    this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: esActual
            ? SurayColors.naranjaQuemado.withOpacity(0.1)
            : SurayColors.blancoHumo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esActual
              ? SurayColors.naranjaQuemado.withOpacity(0.3)
              : SurayColors.grisAntracita.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: esActual
                ? SurayColors.naranjaQuemado
                : SurayColors.azulMarinoProfundo,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
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
            if (esActual)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SurayColors.naranjaQuemado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
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
          'Creado: ${formatDate(usuario.fechaCreacion)}',
          style: TextStyle(
            fontSize: 12,
            color: SurayColors.grisAntracita,
          ),
        ),
        trailing: onEliminar != null
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onEliminar,
                tooltip: 'Eliminar usuario',
              )
            : null,
      ),
    );
  }
}

// --- Botón de cerrar sesión ---

class LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool compact;

  const LogoutButton({
    Key? key,
    required this.onPressed,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 48 : 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// --- Helper de formato de fecha ---

String formatDate(DateTime date) {
  const months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]} ${date.year}';
}
