import 'package:flutter/material.dart';
import '../models/item_model.dart';

class CartItem {
  final ItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class FloatingCart extends StatelessWidget {
  final Map<int, CartItem> cartItems;
  final void Function(int itemId, int change) onUpdateItem;
  final VoidCallback onClearCart;
  final VoidCallback onProceed;

  const FloatingCart({
    super.key,
    required this.cartItems,
    required this.onUpdateItem,
    required this.onClearCart,
    required this.onProceed,
  });

  int get totalItems =>
      cartItems.values.fold(0, (sum, entry) => sum + entry.quantity);

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 250,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cart: $totalItems item(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onClearCart,
                        child: const Text('Clear'),
                      ),
                      ElevatedButton(
                        onPressed: onProceed,
                        child: const Text('Proceed'),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              Column(
                children: cartItems.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.value.item.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Qty: ${entry.value.quantity}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => onUpdateItem(entry.value.item.id, -1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => onUpdateItem(entry.value.item.id, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
