import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _history = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _sortedColumn = 'changed_at'; // Default sorting by date
  bool _isAscending = false; // Default: Newest first

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      List<dynamic> history = await _inventoryService.getInventoryHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory history';
        _isLoading = false;
      });
    }
  }

  // Sorts table based on column clicked
  void _sortTable(String column) {
    setState(() {
      if (_sortedColumn == column) {
        _isAscending = !_isAscending; // Toggle order
      } else {
        _sortedColumn = column;
        _isAscending = true; // Default to ascending
      }

      _history.sort((a, b) {
        var valueA = a[column] ?? '';
        var valueB = b[column] ?? '';

        // Convert numeric values properly before sorting
        if (valueA is int && valueB is int) {
          return _isAscending
              ? valueA.compareTo(valueB)
              : valueB.compareTo(valueA);
        }

        return _isAscending
            ? valueA.toString().compareTo(valueB.toString())
            : valueB.toString().compareTo(valueA.toString());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    sortColumnIndex: [
                      'item_name',
                      'username',
                      'quantity_before',
                      'quantity_change',
                      'quantity_after',
                      'changed_at',
                    ].indexOf(_sortedColumn),
                    sortAscending: _isAscending,
                    columns: [
                      DataColumn(
                        label: const Text('Item'),
                        onSort: (_, __) => _sortTable('item_name'),
                      ),
                      DataColumn(
                        label: const Text('User'),
                        onSort: (_, __) => _sortTable('username'),
                      ),
                      DataColumn(
                        label: const Text('Before'),
                        onSort: (_, __) => _sortTable('quantity_before'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: const Text('Change'),
                        onSort: (_, __) => _sortTable('quantity_change'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: const Text('After'),
                        onSort: (_, __) => _sortTable('quantity_after'),
                        numeric: true,
                      ),
                      DataColumn(
                        label: const Text('Date'),
                        onSort: (_, __) => _sortTable('changed_at'),
                      ),
                    ],
                    rows:
                        _history.map((entry) {
                          return DataRow(
                            cells: [
                              DataCell(
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(entry['item_name'] ?? 'Unknown'),
                                ),
                              ),
                              DataCell(
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(entry['username'] ?? 'Unknown'),
                                ),
                              ),
                              DataCell(
                                Text(entry['quantity_before'].toString()),
                              ),
                              DataCell(
                                Text(
                                  entry['quantity_change'].toString(),
                                  style: TextStyle(
                                    color:
                                        entry['quantity_change'] > 0
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(entry['quantity_after'].toString()),
                              ),
                              DataCell(
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(entry['changed_at']),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
    );
  }
}
