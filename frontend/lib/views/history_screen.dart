import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import 'unit_lift_details_screen.dart';

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
  String _sortedColumn = 'created_at'; // Default sorting by lift date
  bool _isAscending = false; // Default: Newest first

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      List<dynamic> history = await _inventoryService.getInventoryHistory();

      for (final entry in history) {
        final liftId = entry['lift_id'] ?? entry['id'];
        try {
          final items = await _inventoryService.getLiftItemsByLiftId(liftId);
          entry['items'] = items;
        } catch (_) {
          entry['items'] = [];
        }
      }

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

        // Numeric comparison for total_items
        if (column == 'total_items') {
          int aVal = (a['total_items'] ?? 0) is int ? a['total_items'] : int.tryParse(a['total_items']?.toString() ?? '0') ?? 0;
          int bVal = (b['total_items'] ?? 0) is int ? b['total_items'] : int.tryParse(b['total_items']?.toString() ?? '0') ?? 0;
          return _isAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        }
        // Date comparison for created_at and returned_at
        if (column == 'created_at' || column == 'returned_at') {
          DateTime? dateA = DateTime.tryParse(a[column] ?? '');
          DateTime? dateB = DateTime.tryParse(b[column] ?? '');
          if (dateA != null && dateB != null) {
            return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
          }
        }
        // Default string comparison
        return _isAscending
            ? valueA.toString().compareTo(valueB.toString())
            : valueB.toString().compareTo(valueA.toString());
      });
    });
  }

  String _formatDate(String rawDate) {
    final date = DateTime.tryParse(rawDate);
    if (date == null) return '-';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year % 100} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: DataTable(
                      showCheckboxColumn: false,
                      sortColumnIndex: [
                        'unit_name',
                        'username',
                        'status',
                        'total_items',
                        'created_at',
                        'returned_at',
                      ].indexOf(_sortedColumn),
                      sortAscending: _isAscending,
                      columns: [
                        DataColumn(
                          label: const Text('UC'),
                          onSort: (_, __) => _sortTable('unit_name'),
                        ),
                        DataColumn(
                          label: const Text('User'),
                          onSort: (_, __) => _sortTable('username'),
                        ),
                        DataColumn(
                          label: const Text('Estado'),
                          onSort: (_, __) => _sortTable('status'),
                        ),
                        DataColumn(
                          label: const Text('Items'),
                          onSort: (_, __) => _sortTable('total_items'),
                          numeric: true,
                        ),
                        DataColumn(
                          label: const Text('Levantado em'),
                          onSort: (_, __) => _sortTable('created_at'),
                        ),
                        DataColumn(
                          label: const Text('Devolvido em'),
                          onSort: (_, __) => _sortTable('returned_at'),
                        ),
                      ],
                      rows: _history.map((entry) {
                        void navigateToDetails() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UnitLiftDetailsScreen(
                                liftId: entry['lift_id'] ?? entry['id'],
                                unitId: entry['unit_id'] ?? 0,
                                userId: entry['user_id'] ?? 0,
                                liftedItems: List<Map<String, dynamic>>.from(entry['items'] ?? []),
                              ),
                            ),
                          );
                        }
                        return DataRow.byIndex(
                          index: _history.indexOf(entry),
                          onSelectChanged: (_) => navigateToDetails(),
                          cells: [
                            DataCell(Text(entry['unit_name'] ?? '-')),
                            DataCell(Text(entry['username'] ?? '-')),
                            DataCell(Text(entry['status'] == 'active' ? 'Ativo' : 'Devolvido')),
                            DataCell(Text(entry['total_items'].toString())),
                            DataCell(Text(
                              entry['created_at'] != null
                                  ? _formatDate(entry['created_at'])
                                  : '-',
                            )),
                            DataCell(Text(
                              entry['returned_at'] != null
                                  ? _formatDate(entry['returned_at'])
                                  : '-',
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
    );
  }
}
