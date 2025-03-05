import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import 'add_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();

  List<dynamic> _items = []; // Full inventory list
  List<dynamic> _categories = []; // Main categories
  Map<int, List<dynamic>> _subcategories =
      {}; // Subcategories mapped by category ID
  bool _isLoading = true;
  String _errorMessage = '';
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _fetchCategories();
    _getUserRole();

    // Establish WebSocket connection to listen for inventory updates
    _socketService.connect();
    _socketService.listenForInventoryUpdates(() {
      _fetchInventory();
    });
  }

  /// Fetches the user's role (admin/user) from API
  Future<void> _getUserRole() async {
    final role = await _apiService.getUserRole();
    setState(() {
      _userRole = role ?? 'user';
    });
  }

  /// Fetches the full inventory list
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

  /// Fetches main categories and their respective subcategories
  void _fetchCategories() async {
    try {
      List<dynamic> categories = await _inventoryService.getMainCategories();
      setState(() {
        _categories = categories;
      });

      // Fetch subcategories for each main category
      for (var category in categories) {
        _fetchSubcategories(category['id']);
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  /// Fetches subcategories for a given category, including nested subcategories
  void _fetchSubcategories(int categoryId) async {
    try {
      print("Fetching subcategories for category ID: $categoryId");

      List<dynamic> subcategories = await _inventoryService.getSubcategories(
        categoryId,
      );
      if (subcategories.isEmpty) return;

      setState(() {
        _subcategories[categoryId] = subcategories;
      });

      print(
        "✅ Subcategories for category ID $categoryId: ${_subcategories[categoryId]}",
      );

      // Ensure each subcategory fetches its own subcategories recursively
      for (var subcategory in subcategories) {
        if (!_subcategories.containsKey(subcategory['id'])) {
          _fetchSubcategories(subcategory['id']);
        }
      }
    } catch (e) {
      print('❌ Error fetching subcategories for category ID $categoryId: $e');
    }
  }

  /// Returns only the direct items belonging to a specific category
  List<dynamic> _getItemsForCategory(int categoryId) {
    return _items.where((item) => item['category_id'] == categoryId).toList();
  }

  /// Builds UI for categories and subcategories recursively
  Widget _buildCategoryTile(Map<String, dynamic> category) {
    final int categoryId = category['id'];
    final List<dynamic> subcategories = _subcategories[categoryId] ?? [];
    final List<dynamic> items = _getItemsForCategory(categoryId);

    return ExpansionTile(
      key: ValueKey(categoryId),
      title: Text(
        category['name'],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        // Show nested subcategories recursively
        ...subcategories.map((sub) {
          return _buildCategoryTile(sub);
        }),

        // Show actual items under each category/subcategory
        if (items.isNotEmpty) ...[
          const Divider(),
          ...items.map(
            (item) => ListTile(
              title: Text(item['name']),
              subtitle: Text("Quantity: ${item['quantity']}"),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children:
                      _categories
                          .map((category) => _buildCategoryTile(category))
                          .toList(),
                ),
              ),
    );
  }
}
