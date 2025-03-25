import 'package:flutter/material.dart';
import 'admin_users_screen.dart';
import 'export_screen.dart';
import 'history_screen.dart';
import 'dashboard_screen.dart';

/// This screen represents the Admin Dashboard with access to various admin features.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel de Administração')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildAdminOption(
            context,
            icon: Icons.people,
            label: 'Gestão de Utilizadores',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildAdminOption(
            context,
            icon: Icons.file_download,
            label: 'Exportar Inventário',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildAdminOption(
            context,
            icon: Icons.history,
            label: 'Histórico de Alterações',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildAdminOption(
            context,
            icon: Icons.bar_chart,
            label: 'Dashboard / Estatísticas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Builds an individual admin menu option with icon and label
  Widget _buildAdminOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
