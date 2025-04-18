import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class AdminDamagedItemsScreen extends StatefulWidget {
  const AdminDamagedItemsScreen({super.key});

  @override
  State<AdminDamagedItemsScreen> createState() => _AdminDamagedItemsScreenState();
}

class _AdminDamagedItemsScreenState extends State<AdminDamagedItemsScreen> {
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _damagedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchDamagedItems();
  }

  Future<void> _fetchDamagedItems() async {
    try {
      final items = await _inventoryService.getAllDamagedItems();
      setState(() {
        _damagedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar itens danificados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itens Danificados')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _damagedItems.isEmpty
              ? const Center(child: Text('Nenhum item danificado encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _damagedItems.length,
                  itemBuilder: (context, index) {
                    final item = _damagedItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['item_name'] ?? 'Item desconhecido'),
                        subtitle: Text(
                          'UC: ${item['unit_name'] ?? 'Desconhecida'} • Danificados: ${item['quantity']}',
                        ),
                        trailing: Text(
                          item['username'] ?? 'Utilizador',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
