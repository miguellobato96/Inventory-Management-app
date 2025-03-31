import 'package:flutter/material.dart';
import 'package:inventory_flutter/services/inventory_service.dart';
import 'package:inventory_flutter/services/admin_inventory_service.dart';
import 'package:inventory_flutter/views/item_form_screen.dart';
import 'package:inventory_flutter/views/category_form_screen.dart';
import 'package:inventory_flutter/views/location_form_screen.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _locations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadItems(), _loadCategories(), _loadLocations()]);
  }

  Future<void> _loadItems() async {
    try {
      final response = await InventoryService().getInventoryItems();

      final sortedItems = List<Map<String, dynamic>>.from(response)
        ..sort((a, b) {
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

      setState(() => _items = sortedItems);
    } catch (e) {
      _showError('Erro ao carregar items: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final mainCategories = await AdminInventoryService.getCategories();
      List<Map<String, dynamic>> allCategories = [];

      // Sort main categories alphabetically
      mainCategories.sort((a, b) => a['name'].compareTo(b['name']));

      // Recursive function to fetch and sort subcategories
      Future<void> fetchSubcategories(
        Map<String, dynamic> category,
        int level,
      ) async {
        final prefix = '   ' * level + '└ ';
        allCategories.add({
          ...category,
          'name': '$prefix${category['name']}',
          'indentLevel': level,
        });

        try {
          final subs = await AdminInventoryService.getSubcategories(
            category['id'],
          );

          // Sort subcategories alphabetically
          subs.sort((a, b) => a['name'].compareTo(b['name']));

          for (var sub in subs) {
            await fetchSubcategories(sub, level + 1);
          }
        } catch (e) {
          print('Error loading subcategories for ${category['id']}: $e');
        }
      }

      // Start processing each main category
      for (var cat in mainCategories) {
        await fetchSubcategories(cat, 0);
      }

      setState(() => _categories = allCategories);
    } catch (e) {
      _showError('Error loading categories: $e');
    }
  }

  Future<void> _loadLocations() async {
    try {
      final response = await AdminInventoryService.getLocations();

      final sortedLocations = List<Map<String, dynamic>>.from(response)
        ..sort((a, b) => a['name'].compareTo(b['name']));

      setState(() => _locations = sortedLocations);
    } catch (e) {
      _showError('Erro ao carregar localizações: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openItemForm({Map<String, dynamic>? item}) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );

    if (updated == true) {
      _loadItems();
    }
  }

  void _openCategoryForm({Map<String, dynamic>? category}) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );

    if (updated == true) {
      _loadCategories();
    }
  }

  void _openLocationForm({Map<String, dynamic>? location}) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocationFormScreen(location: location)),
    );

    if (updated == true) {
      _loadLocations();
    }
  }

  Widget _buildTabSection({
    required List<Map<String, dynamic>> data,
    required String labelKey,
    required void Function(Map<String, dynamic>) onEdit,
    required VoidCallback onCreate,
  }) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: data.length,
            itemBuilder: (_, index) {
              final item = data[index];
              return ListTile(
                title: Text(item[labelKey]),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(item),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventário (Admin)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Items'),
            Tab(text: 'Categorias'),
            Tab(text: 'Localizações'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Items
          _buildTabSection(
            data: _items,
            labelKey: 'name',
            onEdit: (item) => _openItemForm(item: item),
            onCreate: () => _openItemForm(),
          ),
          // Categories
          _buildTabSection(
            data: _categories,
            labelKey: 'name',
            onEdit: (cat) => _openCategoryForm(category: cat),
            onCreate: () => _openCategoryForm(),
          ),
          // Locations
          _buildTabSection(
            data: _locations,
            labelKey: 'name',
            onEdit: (loc) => _openLocationForm(location: loc),
            onCreate: () => _openLocationForm(),
          ),
        ],
      ),
    );
  }
}
