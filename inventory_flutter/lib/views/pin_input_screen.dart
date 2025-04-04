import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputScreen extends StatefulWidget {
  final Function(String) onPinConfirmed;

  const PinInputScreen({super.key, required this.onPinConfirmed});

  @override
  State<PinInputScreen> createState() => _PinInputScreenState();
}

class _PinInputScreenState extends State<PinInputScreen> {
  final FocusNode _focusNode = FocusNode();
  String _pin = '';
  final Set<String> _highlightedKeys = {};

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

  // Handle PIN input logic
  void _handleInput(String value) {
    setState(() {
      if (value == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4 && value != '') {
        _pin += value;
        _highlightKey(value);

        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 100), () {
            widget.onPinConfirmed(_pin);
          });
        }
      }
    });
  }

  void _highlightKey(String key) {
    setState(() => _highlightedKeys.add(key));
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _highlightedKeys.remove(key));
    });
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

  // Display PIN entry dots
  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
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

  // Build the full numpad with 12 buttons
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

  // Create a single circular numpad button
  Widget _numpadButton(String label, double size) {
    final isHighlighted = _highlightedKeys.contains(label);
    return GestureDetector(
      onTap: () {
        _handleInput(label);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.deepPurple),
          color: isHighlighted ? Colors.deepPurple.withOpacity(0.2) : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? Colors.deepPurple : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _pin.length == 4;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate button size based on half of screen width
    final buttonSize = (screenWidth / 2 - 64) / 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Definir PIN')),
      body: Focus(
        autofocus: true,
        focusNode: _focusNode,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Left column: PIN info
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
                      onPressed:
                          isComplete ? () => widget.onPinConfirmed(_pin) : null,
                      child: const Text('Confirmar PIN'),
                    ),
                  ],
                ),
              ),
              // Right column: Numpad
              Expanded(
                flex: 2,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _buildNumpad(360),
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
