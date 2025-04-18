import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../services/inventory_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/floating_cart.dart';

class UnitSelectionScreen extends StatefulWidget {
  final void Function(UnitModel selectedUnit) onUnitSelected;
  final Map<int, CartItem> cartItems; // Pass CartItems from InventoryScreen
  final UserModel? currentUser; // Pass current user data

  const UnitSelectionScreen({
    super.key,
    required this.onUnitSelected,
    required this.cartItems,
    required this.currentUser,
  });

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  final UserService _userService = UserService();
  final InventoryService _inventoryService = InventoryService();
  List<UnitModel> _units = [];
  bool _isLoading = true;
  UnitModel? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _fetchUserUnits();
  }

  Future<void> _fetchUserUnits() async {
    try {
      final units = await _userService.getUserUnits();
      setState(() {
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching units: $e");
      setState(() => _isLoading = false);
    }
  }

  void _confirmLift() async {
    if (_selectedUnit == null) return;

    // Prepare the list of items to be lifted (from the cart)
    final items =
        widget.cartItems.entries
            .map(
              (entry) => {
                'item_id': entry.value.item.id,
                'quantity': entry.value.quantity,
              },
            )
            .toList();

    // Log for debugging
    print("Items being lifted: $items");
    print("User ID: ${widget.currentUser?.id}");

    // Call the service to confirm the item lift
    final success = await _inventoryService.confirmItemLift(
      userId: widget.currentUser?.id ?? 0,
      unitId: _selectedUnit!.id,
      items: items,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Items levantados com sucesso!")),
      );
      Navigator.pop(context, true); // Close the dialog after successful lift
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falha ao confirmar levantamento.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _selectedUnit == null
          ? const Center(
              child: Text(
                'Selecionar Unidade Curricular',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() => _selectedUnit = null);
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _selectedUnit!.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _units.isEmpty
              ? const Text('Nenhuma unidade curricular encontrada.')
              : SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: _selectedUnit == null
                      ? Scrollbar(
                          child: ListView.builder(
                            itemCount: _units.length,
                            itemBuilder: (context, index) {
                              final unit = _units[index];
                              return ListTile(
                                title: Text(unit.name),
                                onTap: () {
                                  setState(() {
                                    _selectedUnit = unit;
                                  });
                                },
                              );
                            },
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                child: ListView.builder(
                                  itemCount: widget.cartItems.length,
                                  itemBuilder: (context, index) {
                                    final entry = widget.cartItems.entries.elementAt(index);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Material(
                                          color: Colors.transparent,
                                          elevation: 1,
                                          borderRadius: BorderRadius.circular(8),
                                          child: ListTile(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            tileColor: Theme.of(context).cardColor,
                                            title: Text(
                                              entry.value.item.name,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            trailing: Text(
                                              '${entry.value.quantity}',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.center,
                              child: ElevatedButton(
                                onPressed: _confirmLift,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text(
                                  'Confirmar Levantamento',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
    );
  }
}
