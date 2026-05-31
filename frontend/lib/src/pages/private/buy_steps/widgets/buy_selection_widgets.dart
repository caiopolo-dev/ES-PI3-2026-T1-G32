// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widgets do step 0 — seleção de quantidade e preço

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/utils/currency_formatter.dart';
import 'package:mescla_invest/src/pages/private/buy_steps/widgets/buy_steps_widgets.dart';

/// Cartão informativo exibido no passo de seleção (step 0).
///
/// Mostra o saldo/quantidade do usuário, preço por token (quando aplicável)
/// e um resumo rápido de quantos tokens estão disponíveis na startup.
class BuyInfoCard extends StatelessWidget {
  final bool isSellMode;
  final int availableQuantity;
  final int walletBalance;
  final int pricePerTokenCents;
  final Color accentColor;

  const BuyInfoCard({
    super.key,
    required this.isSellMode,
    required this.availableQuantity,
    required this.walletBalance,
    required this.pricePerTokenCents,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinza200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSellMode ? 'Seus tokens' : 'Saldo em conta',
                  style: const TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 12,
                    color: AppColors.cinza500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSellMode
                      ? '$availableQuantity tokens'
                      : CurrencyFormatter.formatCents(walletBalance),
                  style: TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                if (!isSellMode) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatter.formatCents(pricePerTokenCents)} / token',
                    style: const TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 11,
                      color: AppColors.cinza500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.cinza200),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.azul.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.toll_outlined, size: 13, color: AppColors.azul),
                const SizedBox(width: 4),
                Text(
                  '$availableQuantity disponíveis',
                  style: const TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azul,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de entrada formatado para o preço por token.
///
/// Usa `CurrencyFormatter` como `inputFormatter` para garantir que o
/// usuário veja valores em formato monetário enquanto digita. `onChanged`
/// recebe a string formatada (após o formatter) para que o pai possa
/// extrair os centavos.
class BuyPriceField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const BuyPriceField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinza200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Preço por token',
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 14,
              color: AppColors.cinza700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: SizedBox(
              width: 120,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                // Formata a entrada para dinheiro em tempo real (ex: R$ 1,00).
                inputFormatters: [CurrencyFormatter()],
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seletor de quantidade com botões de incremento/decremento.
///
/// A entrada aceita apenas dígitos (`FilteringTextInputFormatter.digitsOnly`)
/// e delega a lógica de validação/ajuste ao widget pai através de
/// `onChanged`, `onSub` e `onSum` para manter o controle de estado único.
class BuyQuantitySelector extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accentColor;
  final int availableQuantity;
  final VoidCallback onSub;
  final VoidCallback onSum;
  final ValueChanged<String> onChanged;

  const BuyQuantitySelector({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.accentColor,
    required this.availableQuantity,
    required this.onSub,
    required this.onSum,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: SizedBox(
            width: 60,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              // Apenas dígitos são permitidos para evitar caracteres não numéricos.
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: onChanged,
            ),
          ),
        ),
        const Spacer(),
        StepButton(label: '−', onPressed: onSub),
        const SizedBox(width: 10),
        StepButton(label: '+', onPressed: onSum),
      ],
    );
  }
}

/// Cartão que mostra o total a pagar/receber para a operação atual.
///
/// Recebe `totalCents` em centavos e o converte com `CurrencyFormatter`.
/// A cor e a label mudam conforme `isSellMode` para deixar claro o fluxo.
class BuyTotalCard extends StatelessWidget {
  final bool isSellMode;
  final int totalCents;
  final Color accentColor;

  const BuyTotalCard({
    super.key,
    required this.isSellMode,
    required this.totalCents,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isSellMode ? 'Você receberá:' : 'Você pagará:',
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          Text(
            CurrencyFormatter.formatCents(totalCents),
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
