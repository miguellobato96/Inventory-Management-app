import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
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
  final ApiService _apiService = ApiService();

  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String? _selectedCategory;
  String _userRole = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _getUserRole();

    // Connect to Socket.io
    _socketService.connect();
    _socketService.listenForInventoryUpdates(() {
      _fetchInventory();
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

  Future<void> _getUserRole() async {
    final role = await _apiService.getUserRole();
    setState(() {
      _userRole = role ?? 'user';
    });
  }

  void _fetchInventory() async {
    try {
      List<dynamic> items = await _inventoryService.getInventoryItems();
      setState(() {
        _items = items;
        _applyFilters(); // Apply filters after fetching data
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems =
          _items.where((item) {
            final matchesSearch = item['name'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final matchesCategory =
                _selectedCategory == null ||
                _selectedCategory == 'All' ||
                item['category'] == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();
    });
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
        actions:
            _userRole == 'admin'
                ? [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final added = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddItemScreen(),
                        ),
                      );
                      if (added == true) {
                        _fetchInventory();
                      }
                    },
                  ),
                ]
                : [],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search Items',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Filter by Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                      _getCategories().map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty
                        ? Center(child: Text(_errorMessage))
                        : ListView.builder(
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
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
                              trailing:
                                  _userRole == 'admin'
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (item['quantity'] < 5)
                                            const Icon(
                                              Icons.warning,
                                              color: Colors.red,
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () async {
                                              final edited =
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              EditItemScreen(
                                                                item: item,
                                                              ),
                                                    ),
                                                  );
                                              if (edited == true) {
                                                _fetchInventory();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: const Text(
                                                        'Confirm Delete',
                                                      ),
                                                      content: const Text(
                                                        'Are you sure you want to delete this item?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                          child: const Text(
                                                            'No',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                          child: const Text(
                                                            'Yes',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );

                                              if (confirm == true) {
                                                final success =
                                                    await _inventoryService
                                                        .deleteItem(item['id']);
                                                if (success) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Item deleted successfully',
                                                      ),
                                                    ),
                                                  );
                                                  _fetchInventory();
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Failed to delete item',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      )
                                      : null,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getCategories() {
    Set<String> categories =
        _items.map((item) => item['category'] as String).toSet();
    return ['All', ...categories];
  }
}
