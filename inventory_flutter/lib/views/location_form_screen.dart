import 'package:flutter/material.dart';
import 'package:inventory_flutter/services/admin_inventory_service.dart';

class LocationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? location;

  const LocationFormScreen({super.key, this.location});

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool get isEditing => widget.location != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameCtrl.text = widget.location!['name'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        await AdminInventoryService.updateLocation(
          widget.location!['id'],
          _nameCtrl.text,
        );
      } else {
        await AdminInventoryService.createLocation(_nameCtrl.text);
      }

      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError("Erro ao guardar localização: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Eliminar Localização"),
            content: const Text(
              "Tens a certeza que queres eliminar esta localização?",
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
        await AdminInventoryService.deleteLocation(widget.location!['id']);
        if (context.mounted) Navigator.pop(context, true);
      } catch (e) {
        _showError("Erro ao eliminar localização: $e");
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
        title: Text(isEditing ? 'Editar Localização' : 'Nova Localização'),
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
                            ? 'Preenche o nome da localização'
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
                      'Eliminar Localização',
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
