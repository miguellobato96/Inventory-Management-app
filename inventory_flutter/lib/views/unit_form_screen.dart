import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../services/user_service.dart';

class UnitFormScreen extends StatefulWidget {
  final UnitModel? unit;

  const UnitFormScreen({super.key, this.unit});

  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final UserService _userService = UserService();

  bool _isSaving = false;
  bool get isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.unit!.name;
    }
  }

  void _saveUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        final updated = await _userService.updateUnit(
          widget.unit!.id,
          _nameController.text.trim(),
        );
        if (updated == null) {
          throw Exception('Erro ao atualizar unidade');
        }
      } else {
        final created = await _userService.createUnit(
          _nameController.text.trim(),
        );
        if (created == null) {
          throw Exception('Erro ao criar unidade');
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('Erro ao guardar UC: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao guardar unidade curricular')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _deleteUnit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Unidade Curricular'),
            content: const Text(
              'Tens a certeza que queres eliminar esta unidade curricular?',
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
      await _userService.deleteUnit(widget.unit!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('Erro ao eliminar UC: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao eliminar unidade curricular')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 600 ? 500.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar UC' : 'Nova UC')),
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Unidade Curricular',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Preenche o nome da UC'
                                : null,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveUnit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(isEditing ? 'Guardar Alterações' : 'Criar UC'),
                  ),
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: TextButton(
                          onPressed: _deleteUnit,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Eliminar UC'),
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
