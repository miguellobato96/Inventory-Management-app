import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class UnitLiftDetailsScreen extends StatefulWidget {
  final int liftId;
  final int unitId;
  final int userId;
  final List<Map<String, dynamic>>? liftedItems;
  final Function()? onReturned;

  const UnitLiftDetailsScreen({
    super.key,
    required this.liftId,
    required this.unitId,
    required this.userId,
    this.liftedItems,
    this.onReturned,
  });

  @override
  State<UnitLiftDetailsScreen> createState() => _UnitLiftDetailsScreenState();
}

class _UnitLiftDetailsScreenState extends State<UnitLiftDetailsScreen> {
  final InventoryService _inventoryService = InventoryService();
  final Map<int, int> _damagedQuantities = {};
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _liftItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.liftedItems != null) {
      _liftItems = widget.liftedItems!;
      _isLoading = false;
    } else {
      _fetchLiftItems();
    }
  }

  Future<void> _fetchLiftItems() async {
    try {
      final items = await _inventoryService.getLiftItemsByLiftId(widget.liftId);
      setState(() {
        _liftItems = List<Map<String, dynamic>>.from(items);
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch lift items: $e');
      setState(() {
        _liftItems = [];
        _isLoading = false;
      });
    }
  }

  void _markDamaged(int itemId, int maxQty) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Marcar como danificado'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Quantidade (máx $maxQty)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final input = int.tryParse(controller.text);
              if (input != null && input >= 0 && input <= maxQty) {
                setState(() => _damagedQuantities[itemId] = input);
              }
              Navigator.pop(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _submitReturn() async {
    setState(() => _isSubmitting = true);

    final allItems = _liftItems.map((item) {
      final itemId = item['item_id'];
      final liftedQty = item['quantity'];
      final damagedQty = _damagedQuantities[itemId] ?? 0;
      final returnedQty = liftedQty - damagedQty;
      return {
        'item_id': itemId,
        'quantity': liftedQty,
        'isDamaged': damagedQty > 0,
        'damagedQuantity': damagedQty,
        'returnedQuantity': returnedQty,
      };
    }).toList();

    try {
      await _inventoryService.returnLift(
        liftId: widget.liftId,
        unitId: widget.unitId,
        userId: widget.userId,
        items: allItems,
        damagedItems: allItems
            .where((item) => item['isDamaged'] == true)
            .map((item) => {
                  'item_id': item['item_id'],
                  'quantity': item['damagedQuantity'],
                })
            .toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Levantamento devolvido com sucesso')),
        );
        widget.onReturned?.call();
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      print('Erro ao devolver levantamento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao devolver levantamento')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Levantamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Text('Clique em cada item para seleccionar danificados (se aplicável).'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _liftItems.length,
                      itemBuilder: (_, index) {
                        final item = _liftItems[index];
                        final itemId = item['item_id'];
                        final itemPath = item['category_path'] ?? '';
                        final itemName = item['item_name'] ?? 'Item #$itemId';
                        final liftedQty = item['quantity'];
                        final damagedQty = _damagedQuantities[itemId] ?? 0;

                        return ListTile(
                          title: Text(itemName),
                          subtitle: Text('$itemPath\nLevantados: $liftedQty, Danificados: $damagedQty'),
                          onTap: () => _markDamaged(itemId, liftedQty),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReturn,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Confirmar Devolução'),
                  ),
                ],
              ),
      ),
    );
  }
}
