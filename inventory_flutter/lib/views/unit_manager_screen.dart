import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../services/user_service.dart';
import 'unit_form_screen.dart';
import '../models/user_model.dart';
import 'unit_history_screen.dart';

class UnitManagerScreen extends StatefulWidget {
  final UserModel currentUser;

  const UnitManagerScreen({super.key, required this.currentUser});

  @override
  State<UnitManagerScreen> createState() => _UnitManagerScreenState();
}

class _UnitManagerScreenState extends State<UnitManagerScreen> {
  final UserService _userService = UserService();
  List<UnitModel> _units = [];
  List<UnitModel> _filteredUnits = [];
  String _searchQuery = '';
  bool _isLoading = true;
  Map<int, int> _activeLiftsByUnit = {};

  @override
  void initState() {
    super.initState();
    _fetchUserUnits();
  }

  // Fetch the list of units assigned to the user.
  Future<void> _fetchUserUnits() async {
    try {
      final units = await _userService.getUserUnits();
      setState(() {
        _units = units;
        _filteredUnits = units;
        _isLoading = false;
      });
      await _fetchActiveLiftCounts();
    } catch (e) {
      print("Error fetching units: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveLiftCounts() async {
    try {
      final counts = <int, int>{};
      for (final unit in _units) {
        final history = await _userService.getUnitLiftHistory(unit.id);
        final activeCount = history.where((lift) => lift['status'] == 'active').length;
        counts[unit.id] = activeCount;
      }
      setState(() {
        _activeLiftsByUnit = counts;
      });
    } catch (e) {
      print("Error fetching lift counts: $e");
    }
  }

  void _filterUnits(String query) {
    final filtered = _units.where((unit) => unit.name.toLowerCase().contains(query.toLowerCase())).toList();
    setState(() {
      _filteredUnits = filtered;
    });
  }

  // Show a dialog to input the unit name and then call the API to create it.
  void _addUnit() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String unitName = '';
        return AlertDialog(
          title: const Text('Adicionar UC'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Unidade Curricular'),
            onChanged: (value) {
              unitName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (unitName.isNotEmpty) {
                  try {
                    final response = await _userService.createUnit(unitName);
                    if (response != null) {
                      setState(() {
                        _units.add(response);
                        _filteredUnits.add(response);
                      });
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    print("Error adding unit: $e");
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  // Show a dialog to edit the unit name and then call the API to update it.
  void _editUnit(UnitModel unit) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnitFormScreen(unit: unit),
      ),
    );
    if (updated == true) _fetchUserUnits();
  }

  Future<void> _openUnitHistory(UnitModel unit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnitHistoryScreen(
          unitId: unit.id,
          unitName: unit.name,
          currentUser: widget.currentUser,
        ),
      ),
    );
    await _fetchUserUnits(); // Ensure lift counters update after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de UCs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Pesquisar unidade curricular...',
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
                        _filterUnits(query);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredUnits.length,
                    itemBuilder: (context, index) {
                      final unit = _filteredUnits[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(unit.name),
                          onTap: () => _editUnit(unit),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_activeLiftsByUnit[unit.id] != null && _activeLiftsByUnit[unit.id]! > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    radius: 12,
                                    child: Text(
                                      '${_activeLiftsByUnit[unit.id]}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.history),
                                tooltip: 'Ver levantamentos',
                                onPressed: () async {
                                  await _openUnitHistory(unit);
                                  await _fetchUserUnits(); // Refresh after returning from history
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUnit,
        tooltip: 'Adicionar unidade curricular',
        child: const Icon(Icons.add),
      ),
    );
  }
}
