import 'package:flutter/material.dart';
import 'package:inventory_flutter/services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

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
  bool _lowStockOnly = false;

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
        lowStockOnly: _lowStockOnly,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 600 ? 500.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text("Exportar Inventário")),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Formato de Exportação",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text("PDF"),
                  value: _selectedFormat == "pdf" || _selectedFormat == "both",
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true && _selectedFormat == "csv") {
                        _selectedFormat = "both";
                      } else if (value == true) {
                        _selectedFormat = "pdf";
                      } else if (_selectedFormat == "both") {
                        _selectedFormat = "csv";
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text("CSV"),
                  value: _selectedFormat == "csv" || _selectedFormat == "both",
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true && _selectedFormat == "pdf") {
                        _selectedFormat = "both";
                      } else if (value == true) {
                        _selectedFormat = "csv";
                      } else if (_selectedFormat == "both") {
                        _selectedFormat = "pdf";
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),

                const Text(
                  "Ordenação",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Toggle: Ordenar por (Nome / Quantidade)
                    Expanded(
                      child: ToggleButtons(
                        isSelected: [_sortBy == "name", _sortBy == "quantity"],
                        onPressed: (index) {
                          setState(() {
                            _sortBy = index == 0 ? "name" : "quantity";
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(
                          minHeight: 36,
                          minWidth: 100,
                        ),
                        children: const [Text("Nome"), Text("Quantidade")],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Toggle: Ordem (↑ ↓)
                    ToggleButtons(
                      isSelected: [_order == "asc", _order == "desc"],
                      onPressed: (index) {
                        setState(() {
                          _order = index == 0 ? "asc" : "desc";
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        minWidth: 40,
                      ),
                      children: const [
                        Icon(Icons.arrow_upward),
                        Icon(Icons.arrow_downward),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CheckboxListTile(
                  title: const Text("Apenas com stock reduzido"),
                  value: _lowStockOnly,
                  onChanged:
                      (value) => setState(() => _lowStockOnly = value ?? false),
                ),

                const SizedBox(height: 16),
                Text(
                  "Email: ${_userEmail ?? "A carregar..."}",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),
                _isExporting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _exportInventory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text("Exportar"),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
