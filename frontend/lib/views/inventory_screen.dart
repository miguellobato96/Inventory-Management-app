import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../services/socket_service.dart';
import 'admin_dashboard_screen.dart';
import '../views/change_user_dialog.dart';
import '../models/user_model.dart';
import '../views/pin_login_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../views/unit_selection_screen.dart';
import '../views/unit_manager_screen.dart';
import '../widgets/floating_cart.dart';
import '../models/item_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final SocketService _socketService = SocketService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final ScrollController _scrollController = ScrollController();
  List<UserModel> _allUsers = [];
  List<dynamic> _items = [];
  List<dynamic> _categories = [];
  final Map<int, List<dynamic>> _subcategories = {};
  final Set<int> _expandedCategories = {};
  String _searchQuery = '';

  bool _isLoading = true;
  String _errorMessage = '';
  String _userRole = 'user';
  UserModel? _currentUser;

  final Map<int, CartItem> _cartItems = {};

  int _activeLiftsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _fetchCategories();
    _getUserRole();
    _initUserData().then((_) => _fetchCurrentUnitLifts());


    _socketService.connect();
    _socketService.listenForInventoryUpdates(() {
      _fetchInventory();
    });
  }

void _selectUnit() async {
  final wasLiftConfirmed = await showDialog<bool>(
    context: context,
    builder: (_) => UnitSelectionScreen(
      onUnitSelected: (unit) => Navigator.pop(context, unit),
      cartItems: _cartItems,
      currentUser: _currentUser,
    ),
  );

  if (wasLiftConfirmed == true) {
    await _fetchCurrentUnitLifts(); // Fetch active lifts again
    _clearCart();       // Clear cart
    _fetchInventory();  // Refresh inventory data
  }
}

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  void _modifyCartQuantity(int itemId, int change) {
    setState(() {
      final item = _items.cast<Map<String, dynamic>>().firstWhere(
        (i) => i['id'] == itemId,
        orElse: () => {},
      );
      if (item.isEmpty) return;

      final stockAvailable = item['quantity'] as int;
      final currentInCart = _cartItems[itemId]?.quantity ?? 0;
      final newCartQuantity = currentInCart + change;

      if (change > 0 && newCartQuantity > stockAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Not enough stock for '${item['name']}'")),
        );
        return;
      }

      if (newCartQuantity > 0) {
        _cartItems[itemId] = CartItem(
          item: ItemModel.fromJson(item),
          quantity: newCartQuantity,
        );
      } else {
        _cartItems.remove(itemId);
      }
    });
  }

  Future<void> _fetchCurrentUnitLifts() async {
    if (_currentUser == null) return;

    try {
      final units = await _userService.getUserUnits();
      int totalActive = 0;

      for (final unit in units) {
        final history = await _userService.getUnitLiftHistory(unit.id);
        final activeCount =
            history.where((lift) => lift['status'] == 'active').length;
        totalActive += activeCount;
      }

      setState(() {
        _activeLiftsCount = totalActive;
      });
    } catch (e) {
      print("Error fetching active lifts: $e");
    }
  }

  // Initialize user data
  Future<void> _initUserData() async {
    final email = await _userService.getUserEmail();
    final users = await _userService.fetchAllUsers();

    final matchedUser = users.firstWhere(
      (u) => u.email.trim().toLowerCase() == email?.trim().toLowerCase(),
      orElse: () => UserModel(id: 0, username: '?', email: '', role: ''),
    );

    setState(() {
      _allUsers = users;
      _currentUser = matchedUser;
    });
  }

  // Fetch user role
  Future<void> _getUserRole() async {
    final role = await _authService.getUserRole();
    setState(() {
      _userRole = role ?? 'user';
    });
  }

  // Fetch inventory items
  Future<void> _fetchInventory() async {
    try {
      List<dynamic> items = await _inventoryService.getInventoryItems();
      setState(() {
        _items =
            items.map((item) {
              final map = Map<String, dynamic>.from(item);
              map['is_low_stock'] = map['is_low_stock'] == true;
              return map;
            }).toList();
      });
      _isLoading = false;

      // Remove items from cart that are no longer in inventory
      _cartItems.removeWhere(
        (key, value) => !_items.any((item) => item['id'] == key),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory';
        _isLoading = false;
      });
    }
  }

  // Fetch categories and subcategories
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
        ); // Ensures full path

        filteredResults.add({
          'id': item['id'],
          'name': item['name'],
          'category_name': categoryPath,
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

  // Returns the full category path for an item
  String _getCategoryHierarchy(int? categoryId) {
    if (categoryId == null || categoryId == 0) return 'No Category';

    List<String> hierarchy = [];
    int? currentCategoryId = categoryId;

    while (currentCategoryId != null && currentCategoryId != 0) {
      var category = _categories.firstWhere(
        (cat) => cat['id'] == currentCategoryId,
        orElse: () {
          // Check in _subcategories if not found in _categories
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
      final int originalStock = entry['quantity'] as int;
      final int inCart = _cartItems[entry['id']]?.quantity ?? 0;
      final int available = (originalStock - inCart).clamp(0, originalStock);

      return ListTile(
        onTap: () {
          _modifyCartQuantity(entry['id'], 1);
        },
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
              ? "Category: ${entry['category_name']}"
              : "",
        ),
        trailing: Text(
          "$available/$originalStock",
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
        title: Row(
          children: [
            // Change User
            IconButton(
              tooltip: "Mudar Utilizador",
              icon: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  (_currentUser != null && _currentUser!.username.isNotEmpty)
                      ? _currentUser!.username.characters.first.toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onPressed: () async {
                final selectedUser = await showDialog<UserModel>(
                  context: context,
                  builder:
                      (_) => ChangeUserDialog(
                        users: _allUsers,
                        onUserSelected: (user) => Navigator.pop(context, user),
                      ),
                );

                if (selectedUser != null) {
                  final pin = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PinLoginScreen(
                            userEmail: selectedUser.email,
                            onPinConfirmed:
                                (pin) => Navigator.pop(context, pin),
                          ),
                    ),
                  );

                  if (pin != null && pin.length == 4) {
                    final success = await _authService.login(
                      selectedUser.email,
                      pin,
                    );

                    if (success) {
                      await _initUserData();
                      _getUserRole();
                      _fetchInventory();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Utilizador mudado com sucesso!"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PIN inválido!")),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(width: 8),

            // Search bar
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pesquisar...',
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
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
          ],
        ),
        actions: [
          // UC Manager
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.school),
                tooltip: 'Unidades Curriculares',
                onPressed: () async {
                  if (_currentUser != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                UnitManagerScreen(currentUser: _currentUser!),
                      ),
                    );
                    _fetchInventory();
                    _fetchCurrentUnitLifts(); // Recarrega contagem depois de possíveis alterações
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Utilizador não carregado!"),
                      ),
                    );
                  }
                },
              ),
              if (_activeLiftsCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeLiftsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // Admin Dashboard
          if (_userRole == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.dashboard),
              tooltip: 'Painel de Administração',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
                _fetchInventory();
              },
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    children:
                        displayCategories
                            .map((category) => _buildCategoryTile(category))
                            .toList(),
                  ),
                  if (_cartItems.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: FloatingCart(
                        cartItems: _cartItems,
                        onUpdateItem: _modifyCartQuantity,
                        onClearCart: _clearCart,
                        onProceed: _selectUnit,
                      ),
                    ),
                ],
              ),
    );
  }
}
