import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  void _fetchInventory() async {
    try {
      List<dynamic> items = await _inventoryService.getInventoryItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Center(
        // Center content clearly
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Max width here
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('Category: ${item['category']}'),
                        trailing: Text('Qty: ${item['quantity']}'),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
