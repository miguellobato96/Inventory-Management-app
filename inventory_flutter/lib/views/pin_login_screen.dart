import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinLoginScreen extends StatefulWidget {
  final Function(String) onPinConfirmed;
  final String userEmail;

  const PinLoginScreen({
    super.key,
    required this.userEmail,
    required this.onPinConfirmed,
  });

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  final FocusNode _focusNode = FocusNode();
  String? _lastPressedKey;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKey);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKey);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel;

      if (key == 'Backspace') {
        _handleInput('⌫');
      } else if (RegExp(r'^[0-9]$').hasMatch(key)) {
        _handleInput(key);
      }
    }
  }

  void _handleInput(String value) {
    setState(() {
      _lastPressedKey = value;

      if (value == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4 && value != '') {
        _pin += value;
        if (_pin.length == 4) {
          Future.delayed(Duration(milliseconds: 100), () {
            widget.onPinConfirmed(_pin);
          });
        }
      }

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _lastPressedKey = null);
        }
      });
    });
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length ? Colors.black : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildNumpad(double width) {
    final spacing = 20.0;
    final buttonSize = ((width - spacing * 4) / 3).clamp(48.0, 72.0);
    final labels = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing,
        runSpacing: spacing,
        children:
            labels.map((label) => _numpadButton(label, buttonSize)).toList(),
      ),
    );
  }

  Widget _numpadButton(String label, double size) {
    final isPressed = _lastPressedKey == label;
    return GestureDetector(
      onTap: () => _handleInput(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed ? Colors.deepPurple.withOpacity(0.2) : null,
          border: Border.all(color: Colors.deepPurple),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: isPressed ? FontWeight.bold : FontWeight.normal,
            color: isPressed ? Colors.deepPurple : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _pin.length == 4;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Introduzir PIN')),
      body: Focus(
        autofocus: true,
        focusNode: _focusNode,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Left: PIN info and button
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PIN de 4 dígitos',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    _buildPinDisplay(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: null,
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
              // Right: Numpad
              Expanded(
                flex: 2,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _buildNumpad(screenWidth),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
