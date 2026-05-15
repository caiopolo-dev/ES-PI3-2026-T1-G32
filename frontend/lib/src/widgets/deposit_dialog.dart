// Autor: Gustavo Alves de Siqueira Costa
// Data: 14/05/2026
// Descrição: Dialog reutilizável para adicionar saldo à carteira

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class DepositDialog extends StatefulWidget {
  const DepositDialog({super.key});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorMsg;

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

  void _submit() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final valor = double.tryParse(raw);
    if (valor == null || valor <= 0) {
      setState(() => _errorMsg = 'Informe um valor válido');
      return;
    }
    if (valor > 10000) {
      setState(() => _errorMsg = 'Máximo R\$ 10.000 por depósito');
      return;
    }
    _pop((valor * 100).round());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: AppColors.branco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
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
            const SizedBox(height: 20),
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
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azul,
                      foregroundColor: AppColors.branco,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Depositar',
                      style: TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
