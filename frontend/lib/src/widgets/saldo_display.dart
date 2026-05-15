// Autor: Gustavo Alves de Siqueira Costa
// Data: 14/05/2026
// Descrição: Widget reutilizável para exibir saldo com toggle de visibilidade

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaldoDisplay extends StatefulWidget {
  final double saldo;
  final String label;
  final Color labelColor;
  final Color balanceColor;
  final Color eyeColor;
  final double balanceFontSize;
  final ValueChanged<bool>? onVisibilityChanged;

  const SaldoDisplay({
    super.key,
    required this.saldo,
    required this.label,
    required this.labelColor,
    required this.balanceColor,
    required this.eyeColor,
    this.balanceFontSize = 28,
    this.onVisibilityChanged,
  });

  @override
  State<SaldoDisplay> createState() => _SaldoDisplayState();
}

class _SaldoDisplayState extends State<SaldoDisplay> {
  bool _visivel = false;

  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 13,
                color: widget.labelColor,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                setState(() => _visivel = !_visivel);
                widget.onVisibilityChanged?.call(_visivel);
              },
              child: Icon(
                _visivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: widget.eyeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _visivel ? _fmt.format(widget.saldo) : 'R\$ ••••••',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: widget.balanceFontSize,
            fontWeight: FontWeight.bold,
            color: widget.balanceColor,
          ),
        ),
      ],
    );
  }
}
