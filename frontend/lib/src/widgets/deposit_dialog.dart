// Autor: Gustavo Alves de Siqueira Costa
// Data: 14/05/2026
// Descrição: Dialog reutilizável para adicionar saldo à carteira

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class DepositDialog extends StatefulWidget {
  const DepositDialog({super.key});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  static const int _maxCents = 5000000; // R$ 50.000,00

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorMsg;
  bool _showConfirmation = false;
  int _amountCents = 0;

  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _pop([int? result]) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  void _goToConfirmation() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(raw);
    if (valor == null || valor <= 0) {
      setState(() => _errorMsg = 'Informe um valor válido');
      return;
    }
    final cents = (valor * 100).round();
    if (cents > _maxCents) {
      setState(() => _errorMsg = 'Máximo R\$ 50.000 por depósito');
      return;
    }
    setState(() {
      _errorMsg = null;
      _amountCents = cents;
      _showConfirmation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: AppColors.branco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: _showConfirmation ? _buildConfirmation() : _buildInput(),
      ),
    );
  }

  Widget _buildInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adicionar saldo',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: AppColors.cinza500),
            const SizedBox(width: 4),
            Text(
              'Limite: R\$ 50.000,00 por depósito',
              style: const TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 12,
                color: AppColors.cinza500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Valor (R\$)',
            labelStyle: const TextStyle(color: AppColors.cinza700),
            floatingLabelStyle: const TextStyle(color: AppColors.azul),
            hintText: 'Ex: 100,00',
            errorText: _errorMsg,
            filled: true,
            fillColor: AppColors.cinza100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cinza300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cinza300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.azul, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cinza200,
                  foregroundColor: AppColors.preto,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _goToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azul,
                  foregroundColor: AppColors.branco,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.verde.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.verde,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Confirmar depósito',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _fmt.format(_amountCents / 100),
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.verde,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'serão adicionados à sua carteira',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 13,
            color: AppColors.cinza500,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _showConfirmation = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cinza200,
                  foregroundColor: AppColors.preto,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _pop(_amountCents),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  foregroundColor: AppColors.branco,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
