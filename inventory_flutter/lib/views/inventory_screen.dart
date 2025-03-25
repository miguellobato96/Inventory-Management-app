import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();

  final ScrollController _scrollController = ScrollController();
  List<dynamic> _items = [];
  List<dynamic> _categories = [];
  final Map<int, List<dynamic>> _subcategories = {};
  final Set<int> _expandedCategories = {};
  String _searchQuery = '';

  bool _isLoading = true;
  String _errorMessage = '';
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _fetchCategories();
    _getUserRole();

    _socketService.connect();
    _socketService.listenForInventoryUpdates(() {
      _fetchInventory();
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
        _items =
            items.map((item) {
              return {
                ...item,
                "is_low_stock":
                    item["is_low_stock"] == true, // Ensure it's a boolean
              };
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory';
        _isLoading = false;
      });
    }
  }

  void _fetchCategories() async {
    try {
      List<dynamic> categories = await _inventoryService.getMainCategories();
      setState(() {
        _categories = categories;
      });

      for (var category in categories) {
        _fetchSubcategories(category['id']);
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void _fetchSubcategories(int categoryId) async {
    try {
      List<dynamic> subcategories = await _inventoryService.getSubcategories(
        categoryId,
      );
      if (subcategories.isEmpty) return;

      setState(() {
        for (var subcategory in subcategories) {
          subcategory['parent_id'] =
              categoryId; // ✅ Store parent ID for hierarchy tracking
        }
        _subcategories[categoryId] = subcategories;
      });

      for (var subcategory in subcategories) {
        if (!_subcategories.containsKey(subcategory['id'])) {
          _fetchSubcategories(subcategory['id']);
        }
      }
    } catch (e) {
      print('Error fetching subcategories for category ID $categoryId: $e');
    }
  }

  // Filters inventory based on search input
  List<Map<String, dynamic>> _filterInventoryBySearch() {
    if (_searchQuery.isEmpty) {
      _expandedCategories.clear();
      return _categories
          .map((category) => _buildCategoryHierarchy(category))
          .toList();
    }

    List<Map<String, dynamic>> filteredResults = [];

    // Search Categories
    for (var category in _categories) {
      if (category['name'].toLowerCase().contains(_searchQuery.toLowerCase())) {
        filteredResults.add(_buildCategoryHierarchy(category));
      }
    }

    // Search Subcategories
    for (var entry in _subcategories.entries) {
      for (var sub in entry.value) {
        if (sub['name'].toLowerCase().contains(_searchQuery.toLowerCase())) {
          filteredResults.add(_buildCategoryHierarchy(sub));
        }
      }
    }

    // Search Items and Ensure Full Category Path
    for (var item in _items) {
      if (item['name'].toLowerCase().contains(_searchQuery.toLowerCase())) {
        String categoryPath = _getCategoryHierarchy(
          item['category_id'],
        ); // ✅ Ensures full path

        filteredResults.add({
          'id': item['id'],
          'name': item['name'],
          'category_name': categoryPath, // ✅ Correct Full Path!
          'quantity': item['quantity'],
          'type': 'item',
        });
      }
    }

    return filteredResults;
  }

  // Builds the category hierarchy including subcategories and items
  Map<String, dynamic> _buildCategoryHierarchy(Map<String, dynamic> category) {
    int categoryId = category['id'];
    String categoryPath = _getCategoryHierarchy(categoryId);

    return {
      'id': categoryId,
      'name': category['name'],
      'category_name': categoryPath,
      'subcategories':
          _subcategories[categoryId]
              ?.map((sub) => _buildCategoryHierarchy(sub))
              .toList() ??
          [],
      'items': _getItemsForCategory(categoryId),
      'type': 'category',
    };
  }

  // Returns the list of items within a specific category
  List<dynamic> _getItemsForCategory(int categoryId) {
    return _items.where((item) => item['category_id'] == categoryId).toList();
  }

  // Adjusts the quantity of an item and shows location output
  void _modifyQuantity(int itemId, int quantityChange) async {
    Map<String, dynamic>? updatedItem = await _inventoryService
        .adjustItemQuantity(itemId, quantityChange);

    if (updatedItem != null) {
      _fetchInventory(); // Refresh inventory to show updated quantity

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item quantity updated successfully!\nLocation: ${updatedItem['location_name']}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update item quantity!')),
      );
    }
  }

  // Shows a dialog to add or take quantity for an item
  void _showQuantityDialog(
    BuildContext context,
    String action,
    int itemId,
    String itemName,
  ) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(itemName),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Enter quantity",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                int? quantity = int.tryParse(quantityController.text);

                // Prevent invalid input
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Quantity should be greater than zero."),
                    ),
                  );
                  return;
                }

                // Simulate API request to check if stock would go negative
                int currentQuantity =
                    _items.firstWhere(
                      (item) => item['id'] == itemId,
                    )['quantity'];
                if (action == "remove" && currentQuantity - quantity < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Not enough stock!")),
                  );
                  return; // ❌ Keep dialog open
                }

                // Close dialog and update quantity
                Navigator.pop(context);
                _modifyQuantity(itemId, action == "add" ? quantity : -quantity);
              },
              child: Text(action == "add" ? "Add" : "Take"),
            ),
          ],
        );
      },
    );
  }

  // Returns the full category path for an item
  String _getCategoryHierarchy(int? categoryId) {
    if (categoryId == null || categoryId == 0) return 'No Category';

    List<String> hierarchy = [];
    int? currentCategoryId = categoryId;

    while (currentCategoryId != null && currentCategoryId != 0) {
      var category = _categories.firstWhere(
        (cat) => cat['id'] == currentCategoryId,
        orElse: () {
          // ✅ Check in _subcategories if not found in _categories
          for (var entry in _subcategories.entries) {
            for (var sub in entry.value) {
              if (sub['id'] == currentCategoryId) {
                return sub;
              }
            }
          }
          return {'id': 0, 'name': 'Unknown', 'parent_id': 0};
        },
      );

      if (category['id'] == 0 || category['name'] == 'Unknown') break;

      hierarchy.insert(0, category['name']);
      currentCategoryId = category['parent_id'];
    }

    return hierarchy.isNotEmpty ? hierarchy.join(' > ') : 'No Category';
  }

  // Builds category, subcategory, or item tile
  Widget _buildCategoryTile(Map<String, dynamic> entry) {
    final int entryId = entry['id'];
    final String entryName = entry['name'];
    final String entryType = entry['type'] ?? 'category';
    final List<dynamic> subcategories = entry['subcategories'] ?? [];
    final List<dynamic> items = entry['items'] ?? [];

    // Item
    if (entryType == 'item') {
      return ListTile(
        leading:
            entry.containsKey("is_low_stock") && entry["is_low_stock"] == true
                ? Icon(Icons.warning, color: Colors.red)
                : null,
        title: Text(
          entryName,
          style: const TextStyle(fontWeight: FontWeight.normal),
        ),
        subtitle: Text(
          entry.containsKey('category_name') &&
                  entry['category_name'].isNotEmpty
              ? "Category: ${entry['category_name']} | Quantity: ${entry['quantity']}"
              : "Quantity: ${entry['quantity']}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.red),
              onPressed:
                  () => _showQuantityDialog(
                    context,
                    "remove",
                    entry['id'],
                    entry['name'],
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed:
                  () => _showQuantityDialog(
                    context,
                    "add",
                    entry['id'],
                    entry['name'],
                  ),
            ),
          ],
        ),
      );
    }

    // Category or Subcategory
    return ExpansionTile(
      key: ValueKey(entryId),
      title: Text(
        entryName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: _expandedCategories.contains(entryId),
      onExpansionChanged: (expanded) {
        setState(() {
          if (expanded) {
            _expandedCategories.add(entryId); // Track expanded categories
          } else {
            _expandedCategories.remove(entryId);
          }
        });
      },
      children: [
        if (subcategories.isNotEmpty)
          ...subcategories.map((sub) => _buildCategoryTile(sub)),

        if (items.isNotEmpty) const Divider(),

        if (items.isNotEmpty)
          ...items.map(
            (item) => _buildCategoryTile({
              'id': item['id'],
              'name': item['name'],
              'category_name': _getCategoryHierarchy(item['category_id']),
              'quantity': item['quantity'],
              'is_low_stock': item['is_low_stock'],
              'type': 'item',
            }),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayCategories = _filterInventoryBySearch();
    return Scaffold(
      appBar: AppBar(
        title: Expanded(
          child: SizedBox(
            height: 40, // Adjust height to match icon size
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                ), // Align text properly
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Slight rounding
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(
                  0.2,
                ), // Maintain theme consistency
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (query) {
                if (mounted) {
                  setState(() {
                    _searchQuery = query;
                  });
                }
              },
            ),
          ),
        ),
        actions: [
          // Admin Dashboard
          if (_userRole == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.dashboard),
              tooltip: 'Painel de Administração',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
              },
            ),
          ],
          const SizedBox(width: 16), // Espaçamento à direita
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView(
                children:
                    displayCategories
                        .map((category) => _buildCategoryTile(category))
                        .toList(),
              ),
    );
  }
}
