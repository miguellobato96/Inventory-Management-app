import 'package:flutter/material.dart';
import '../services/admin_user_service.dart';
import 'unit_lift_details_screen.dart';

class UserHistoryScreen extends StatefulWidget {
  final int userId;
  final String username;

  const UserHistoryScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  final AdminUserService _userService = AdminUserService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // Load user-specific inventory change history
  void _fetchHistory() async {
    try {
      final data = await _userService.getUserHistory(widget.userId);
      setState(() {
        _history = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar histórico')),
      );
    }
  }

  // Display a single history entry
  Widget _buildHistoryRow(dynamic entry) {
    final isAddition = (entry['quantity_change'] ?? 0) > 0;
    final color = isAddition ? Colors.green : Colors.red;
    final sign = isAddition ? '+' : '';

    return GestureDetector(
      onTap: () {
        if (entry['lift_id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UnitLiftDetailsScreen(
                liftId: entry['lift_id'],
                unitId: entry['unit_id'],
                userId: widget.userId,
                liftedItems: entry['lifted_items'] ?? [],
              ),
            ),
          );
        }
      },
      child: ListTile(
        title: Text(entry['item_name']),
        subtitle: Text(
          '${entry['quantity_before']} → ${entry['quantity_after']} ($sign${entry['quantity_change']})',
          style: TextStyle(color: color),
        ),
        trailing: Text(
          entry['changed_at'].toString().split('T').first,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histórico: ${widget.username}')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
              ? const Center(child: Text('Sem registos disponíveis.'))
              : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  return _buildHistoryRow(_history[index]);
                },
              ),
    );
  }
}
