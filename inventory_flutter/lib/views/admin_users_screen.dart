import 'package:flutter/material.dart';
import '../services/admin_user_service.dart';
import 'user_form_screen.dart';
import 'user_history_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersScreen> {
  final AdminUserService _userService = AdminUserService();
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Load users from the backend
  void _fetchUsers() async {
    try {
      final users = await _userService.getAllUsers();

      // Sort by username (case-insensitive)
      users.sort(
        (a, b) =>
            a['username'].toLowerCase().compareTo(b['username'].toLowerCase()),
      );

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar utilizadores: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar utilizadores')),
      );
    }
  }

  // Filter users by name or email
  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredUsers =
          _users.where((user) {
            final username = user['username'].toLowerCase();
            final email = user['email'].toLowerCase();
            return username.contains(query.toLowerCase()) ||
                email.contains(query.toLowerCase());
          }).toList();
    });
  }

  // Navigate to edit user form
  void _openUserEditor(dynamic user) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (updated == true) _fetchUsers();
  }

  // Navigate to create user form
  void _openCreateUser() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserFormScreen()),
    );
    if (created == true) _fetchUsers();
  }

  // Navigate to user history screen
  void _openUserHistory(dynamic user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => UserHistoryScreen(
              userId: user['id'],
              username: user['username'],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Utilizadores')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Pesquisar utilizador...',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (query) {
                        if (mounted) {
                          setState(() {
                            _searchQuery = query;
                          });
                          _filterUsers(query);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(user['username']),
                            subtitle: Text(
                              '${user['email']} • ${user['role']}',
                            ),
                            onTap: () => _openUserEditor(user),
                            trailing: IconButton(
                              icon: const Icon(Icons.history),
                              tooltip: 'Ver histórico',
                              onPressed: () => _openUserHistory(user),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateUser,
        tooltip: 'Adicionar utilizador',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
