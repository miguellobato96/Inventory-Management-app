import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_flutter/services/auth_service.dart';
import 'pin_login_screen.dart';
import 'inventory_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool isLoading = false;

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel;
      if ((key == 'Enter' || key == 'NumpadEnter') && !isLoading) {
        login();
      }
    }
  }

  void login() async {
    print("Opening PIN screen...");

    final enteredPin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder:
            (_) => PinLoginScreen(
              userEmail: _emailController.text.trim(),
              onPinConfirmed: (pin) {
                print("PIN entered: $pin");
                Navigator.pop(context, pin);
              },
            ),
      ),
    );

    print("Returned from PIN screen with: $enteredPin");

    if (enteredPin == null || enteredPin.length != 4) return;

    setState(() => isLoading = true);

    final success = await _authService.login(
      _emailController.text.trim(),
      enteredPin,
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login bem-sucedido!')));
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InventoryScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login falhou!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: _handleKey,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Inventory App',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email input field
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
