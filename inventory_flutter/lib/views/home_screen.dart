import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'history_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _userRole = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  // Fetch user role from backend
  Future<void> _fetchUserRole() async {
    final role = await _apiService.getUserRole();
    setState(() {
      _userRole = role ?? 'user';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryScreen(),
                  ),
                );
              },
              child: const Text('Inventory'),
            ),

            const SizedBox(height: 20), // Adds spacing
            // Show history button ONLY for admins
            if (_userRole == 'admin')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                child: const Text('History'),
              ),
          ],
        ),
      ),
    );
  }
}
