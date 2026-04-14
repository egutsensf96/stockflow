import 'package:flutter/material.dart';

import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(top: 60, bottom: 30),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Juan Pérez",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Administrador de Almacén",
                style: TextStyle(color: Colors.blue.shade100),
              ),
            ],
          ),
        ),

        // Options List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle("Gestión de Trabajo"),
              _buildProfileOption(
                Icons.work_outline,
                "Ver Trabajos Actuales",
                () {},
              ),
              _buildProfileOption(
                Icons.add_business_outlined,
                "Agregar Nuevo Trabajo",
                () {},
              ),
              _buildProfileOption(
                Icons.edit_note,
                "Renombrar / Actualizar Trabajo",
                () {},
              ),
              _buildProfileOption(
                Icons.delete_sweep_outlined,
                "Eliminar Trabajo",
                () {},
                isDestructive: true,
              ),

              const Divider(height: 40),

              _buildSectionTitle("Cuenta"),
              _buildProfileOption(
                Icons.settings_outlined,
                "Configuración",
                () {},
              ),
              _buildProfileOption(Icons.logout, "Cerrar Sesión", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }, isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.blue.shade900,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
