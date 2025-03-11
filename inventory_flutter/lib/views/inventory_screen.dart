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

  /// 🏷️ **Returns the list of items within a specific category.**
  List<dynamic> _getItemsForCategory(int categoryId) {
    return _items.where((item) => item['category_id'] == categoryId).toList();
  }

  /// Returns the full category path for an item (e.g., "Electronics > Resistors > 10K Ω")
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
      currentCategoryId =
          category['parent_id']; // ✅ Correctly moves up the hierarchy
    }

    return hierarchy.isNotEmpty ? hierarchy.join(' > ') : 'No Category';
  }

  /// Recursively builds categories, subcategories, and items with correct expansion.
  Widget _buildCategoryTile(Map<String, dynamic> entry) {
    final int entryId = entry['id'];
    final String entryName = entry['name'];
    final String entryType = entry['type'] ?? 'category';
    final List<dynamic> subcategories = entry['subcategories'] ?? [];
    final List<dynamic> items = entry['items'] ?? [];

    // ✅ Fix: Ensure Items Display Full Category Path
    if (entryType == 'item') {
      return ListTile(
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
      );
    }

    // Ensure Categories & Subcategories Expand Properly
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
            _expandedCategories.add(entryId);
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
            (item) => ListTile(
              title: Text(item['name']),
              subtitle: Text(
                "Quantity: ${item['quantity']} | ${_getCategoryHierarchy(item['category_id'])}",
              ),
            ),
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
        title: SizedBox(
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