import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/inventory_service.dart';
import '../models/user_model.dart';
import 'unit_lift_details_screen.dart';

class UnitHistoryScreen extends StatefulWidget {
  final int unitId;
  final String unitName;
  final UserModel currentUser;

  const UnitHistoryScreen({
    super.key,
    required this.unitId,
    required this.unitName,
    required this.currentUser,
  });

  @override
  State<UnitHistoryScreen> createState() => _UnitHistoryScreenState();
}

class _UnitHistoryScreenState extends State<UnitHistoryScreen> {
  final UserService _userService = UserService();
  final InventoryService _inventoryService = InventoryService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await _userService.getUnitLiftHistory(widget.unitId);

      // Fetch items for each lift
      for (final lift in history) {
        final liftId = lift['id'] ?? lift['lift_id'];
        try {
          final items = await _inventoryService.getLiftItemsByLiftId(liftId);
          lift['items'] = items;
        } catch (e) {
          lift['items'] = [];
        }
      }

      history.sort(
        (a, b) => DateTime.parse(
          b['created_at'],
        ).compareTo(DateTime.parse(a['created_at'])),
      );

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar histórico: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final weekdayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final weekday = weekdayNames[local.weekday - 1];
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().substring(2);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$weekday $day-$month-$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de ${widget.unitName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Sem levantamentos para esta UC.'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text('Levantamentos:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._history.map((lift) => Card(
                          color: (lift['status']?.toString().toLowerCase() ?? '') == 'active'
                              ? Colors.orange.shade100
                              : null,
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lift['created_at'] != null
                                        ? 'Levantado em: ${_formatDateTime(DateTime.parse(lift['created_at']))}'
                                        : 'Levantado em: -',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    lift['returned_at'] != null
                                        ? 'Devolvido em: ${_formatDateTime(DateTime.parse(lift['returned_at']))}'
                                        : lift['status'] == 'active'
                                          ? 'Estado: Ativo'
                                          : '',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: lift['status'] == 'active' ? Colors.green : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: null,
                            onTap: () async {
                              final liftedItems = List<Map<String, dynamic>>.from(lift['items'] ?? []);
                              final rawLiftId = lift['id'] ?? lift['lift_id'];
                              if (rawLiftId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Erro: Este levantamento não tem ID válido.')),
                                );
                                return;
                              }
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UnitLiftDetailsScreen(
                                    liftId: rawLiftId,
                                    unitId: lift['unit_id'] ?? 0,
                                    userId: widget.currentUser.id,
                                    liftedItems: liftedItems,
                                    onReturned: _fetchHistory,
                                  ),
                                ),
                              );
                            },
                          ),
                        )),
                  ],
                ),
    );
  }
}
