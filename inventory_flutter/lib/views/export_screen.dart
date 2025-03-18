import 'package:flutter/material.dart';
import 'package:inventory_flutter/services/export_service.dart';

class ExportScreen extends StatefulWidget {
  @override
  _ExportScreenState createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _selectedFormat = "both";
  String _sortBy = "name";
  String _order = "asc";
  String? _userEmail;
  int? _selectedCategory;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  void _fetchUserEmail() async {
    try {
      String? email = await ExportService.getUserEmail();
      setState(() {
        _userEmail = email;
      });
    } catch (error) {
      _showSnackbar("Failed to load user email: $error");
    }
  }

  void _exportInventory() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final response = await ExportService.exportInventory(
        format: _selectedFormat,
        categoryId: _selectedCategory,
        sortBy: _sortBy,
        order: _order,
      );

      _showSnackbar(response["message"] ?? "Export successful!");
    } catch (error) {
      _showSnackbar("Error exporting: $error");
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Export Inventory")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Export Format:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedFormat,
              onChanged: (value) => setState(() => _selectedFormat = value!),
              items: [
                DropdownMenuItem(value: "csv", child: Text("CSV")),
                DropdownMenuItem(value: "pdf", child: Text("PDF")),
                DropdownMenuItem(value: "both", child: Text("Both")),
              ],
            ),
            SizedBox(height: 10),

            Text(
              "Sort By:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _sortBy,
              onChanged: (value) => setState(() => _sortBy = value!),
              items: [
                DropdownMenuItem(value: "name", child: Text("Name")),
                DropdownMenuItem(value: "quantity", child: Text("Quantity")),
              ],
            ),
            SizedBox(height: 10),

            Text(
              "Order:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _order,
              onChanged: (value) => setState(() => _order = value!),
              items: [
                DropdownMenuItem(value: "asc", child: Text("Ascending")),
                DropdownMenuItem(value: "desc", child: Text("Descending")),
              ],
            ),
            SizedBox(height: 10),

            Text(
              "Email: ${_userEmail ?? "Loading..."}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            Spacer(), // Pushes the button to the bottom

            if (_isExporting)
              Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity, // Make button full-width
                child: ElevatedButton(
                  onPressed: _exportInventory,
                  child: Text("Export"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
