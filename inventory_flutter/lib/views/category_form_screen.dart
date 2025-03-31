import 'package:flutter/material.dart';
import 'package:inventory_flutter/services/admin_inventory_service.dart';

class CategoryFormScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool get isEditing => widget.category != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameCtrl.text = widget.category!['name'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        await AdminInventoryService.updateCategory(
          widget.category!['id'],
          _nameCtrl.text,
        );
      } else {
        await AdminInventoryService.createCategory(_nameCtrl.text);
      }

      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError("Erro ao guardar categoria: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Eliminar Categoria"),
            content: const Text(
              "Tens a certeza que queres eliminar esta categoria?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Eliminar"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await AdminInventoryService.deleteCategory(widget.category!['id']);
        if (context.mounted) Navigator.pop(context, true);
      } catch (e) {
        _showError("Erro ao eliminar categoria: $e");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Categoria' : 'Nova Categoria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator:
                    (val) =>
                        val == null || val.isEmpty
                            ? 'Preenche o nome da categoria'
                            : null,
              ),
              const SizedBox(height: 32),
              _isSaving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Guardar' : 'Criar'),
                  ),
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: TextButton(
                    onPressed: _delete,
                    child: const Text(
                      'Eliminar Categoria',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
