import 'package:flutter/material.dart';
import 'package:inventory_flutter/services/admin_inventory_service.dart';

class ItemFormScreen extends StatefulWidget {
  final Map<String, dynamic>? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _locations = [];

  int? _selectedCategoryId;
  int? _selectedLocationId;

  bool _isSaving = false;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _loadData();

    if (isEditing) {
      final item = widget.item!;
      _nameCtrl.text = item['name'] ?? '';
      _quantityCtrl.text = item['quantity'].toString();
      _thresholdCtrl.text = item['low_stock_threshold'].toString();
      _selectedCategoryId = item['category_id'];
      _selectedLocationId = item['location_id'];
    }
  }

  Future<void> _loadData() async {
    try {
      final categories = await AdminInventoryService.getCategories();
      final locations = await AdminInventoryService.getLocations();

      setState(() {
        _categories = categories;
        _locations = locations;
      });
    } catch (e) {
      _showSnackbar("Erro ao carregar dados: $e");
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        await AdminInventoryService.updateItem(
          id: widget.item!['id'],
          name: _nameCtrl.text,
          quantity: int.parse(_quantityCtrl.text),
          lowStockThreshold: int.parse(_thresholdCtrl.text),
          categoryId: _selectedCategoryId,
          locationId: _selectedLocationId,
        );
      } else {
        await AdminInventoryService.createItem(
          name: _nameCtrl.text,
          quantity: int.parse(_quantityCtrl.text),
          lowStockThreshold: int.parse(_thresholdCtrl.text),
          categoryId: _selectedCategoryId,
          locationId: _selectedLocationId,
        );
      }

      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackbar("Erro ao guardar item: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Eliminar Item"),
            content: const Text(
              "Tens a certeza que queres eliminar este item?",
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
        await AdminInventoryService.deleteItem(widget.item!['id']);
        if (context.mounted) Navigator.pop(context, true);
      } catch (e) {
        _showSnackbar("Erro ao eliminar item: $e");
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 500.0 : double.infinity;
    final seenCategoryIds = <int>{};
    final uniqueCategoryItems =
        _categories
            .where((cat) {
              if (seenCategoryIds.contains(cat['id'])) return false;
              seenCategoryIds.add(cat['id']);
              return true;
            })
            .map<DropdownMenuItem<int>>(
              (cat) => DropdownMenuItem<int>(
                value: cat['id'],
                child: Text(cat['name']),
              ),
            )
            .toList();

    // Verifies if the selected category still exists
    if (_selectedCategoryId != null &&
        !uniqueCategoryItems.any((item) => item.value == _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    // Garantir que a localização selecionada ainda existe
    if (_selectedLocationId != null &&
        !_locations.any((loc) => loc['id'] == _selectedLocationId)) {
      _selectedLocationId = null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Editar Item" : "Novo Item")),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Preenche o nome'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: uniqueCategoryItems,
                    onChanged:
                        (value) => setState(() => _selectedCategoryId = value),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Insere quantidade'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _selectedLocationId,
                    decoration: const InputDecoration(labelText: 'Localização'),
                    items:
                        _locations
                            .map<DropdownMenuItem<int>>(
                              (loc) => DropdownMenuItem<int>(
                                value: loc['id'],
                                child: Text(loc['name']),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() => _selectedLocationId = value),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _thresholdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo (para alerta)',
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Define o limite de stock reduzido'
                                : null,
                  ),
                  const SizedBox(height: 32),

                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _saveItem,
                        child: Text(
                          isEditing ? 'Guardar Alterações' : 'Criar Item',
                        ),
                      ),

                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: TextButton(
                          onPressed: _deleteItem,
                          child: const Text(
                            'Eliminar Item',
                            style: TextStyle(color: Colors.red),
                          ),
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
