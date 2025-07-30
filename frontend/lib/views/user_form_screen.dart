import 'package:flutter/material.dart';
import '../services/admin_user_service.dart';
import 'pin_input_screen.dart';

class UserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _pin;

  final AdminUserService _userService = AdminUserService();
  bool _isSaving = false;
  bool _isAdmin = false;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _usernameCtrl.text = widget.user!['username'];
      _emailCtrl.text = widget.user!['email'];
      _isAdmin = widget.user!['role'] == 'admin';
    }
  }

  // Opens the PIN screen and returns the result
  Future<void> _openPinInput() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PinInputScreen(
              onPinConfirmed: (value) {
                Navigator.pop(context, value);
              },
            ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _pin = result;
      });
    }
  }

  // Save or update user
  void _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pin == null || _pin!.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Define um PIN de 4 dígitos')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _isAdmin ? 'admin' : 'user',
      'password': _pin, // PIN is used as password
    };

    try {
      if (isEditing) {
        await _userService.updateUser(widget.user!['id'], data);
      } else {
        await _userService.createUser(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('Erro ao guardar utilizador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao guardar utilizador')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Delete user (only in edit mode)
  void _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Utilizador'),
            content: const Text(
              'Tens a certeza que queres eliminar este utilizador?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _userService.deleteUser(widget.user!['id']);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('Erro ao eliminar utilizador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao eliminar utilizador')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinDefined = _pin != null && _pin!.length == 4;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 600 ? 500.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Utilizador' : 'Novo Utilizador'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Username
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Preenche o username'
                                : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator:
                        (value) =>
                            value == null || !value.contains('@')
                                ? 'Email inválido'
                                : null,
                  ),
                  const SizedBox(height: 20),

                  // PIN button + Admin toggle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openPinInput,
                        icon: const Icon(Icons.lock),
                        label: Text(
                          pinDefined
                              ? isEditing
                                  ? 'Resetar PIN'
                                  : 'PIN definido'
                              : isEditing
                              ? 'Resetar PIN'
                              : 'Definir PIN',
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 14),
                          backgroundColor: Colors.deepPurple.shade100,
                          foregroundColor: Colors.deepPurple,
                        ),
                      ),
                      const Spacer(),
                      const Text('Administrador'),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isAdmin,
                        onChanged: (val) => setState(() => _isAdmin = val),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Create or save button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Guardar Alterações' : 'Criar Utilizador',
                    ),
                  ),

                  // Centered delete button
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: TextButton(
                          onPressed: _deleteUser,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Eliminar Utilizador'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
