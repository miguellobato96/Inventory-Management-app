import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../services/socket_service.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final SocketService _socketService = SocketService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInventory();

    // Connect to Socket.io
    _socketService.connect();
    _socketService.listenForInventoryUpdates(() {
      _fetchInventory(); // Refresh inventory list on updates
    });

    // Listen for low-stock warnings
    _socketService.listenForLowStockWarnings((lowStockItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Low stock: ${lowStockItem['name']} (Only ${lowStockItem['quantity']} left)',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
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
  void dispose() {
    _socketService.disconnect(); // Disconnect when leaving screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final added = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddItemScreen()),
              );
              if (added == true) {
                _fetchInventory(); // Refresh after adding item
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
                        title: Text('Name: ${item['name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${item['category']}'),
                            Text(
                              'Quantity: ${item['quantity']}',
                              style: TextStyle(
                                color:
                                    (item['quantity'] < 5)
                                        ? Colors.red
                                        : Colors.black,
                                fontWeight:
                                    (item['quantity'] < 5)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item['quantity'] < 5)
                              const Icon(
                                Icons.warning,
                                color: Colors.red,
                              ), // Low-stock warning icon
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final edited = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditItemScreen(item: item),
                                  ),
                                );
                                if (edited == true) {
                                  _fetchInventory(); // Refresh after editing
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: const Text(
                                          'Are you sure you want to delete this item?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  final success = await _inventoryService
                                      .deleteItem(item['id']);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Item deleted successfully',
                                        ),
                                      ),
                                    );
                                    _fetchInventory(); // Refresh inventory
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to delete item'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
