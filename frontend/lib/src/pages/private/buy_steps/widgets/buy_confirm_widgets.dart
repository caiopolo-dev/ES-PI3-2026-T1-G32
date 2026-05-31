// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widgets do step 1 — confirmação e sucesso

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/utils/currency_formatter.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/buy_steps/widgets/buy_steps_widgets.dart';

/// Widget de revisão/confirmação (passo 1) antes de executar a compra/venda.
///
/// Mostra:
/// - `startupName` e quantidade selecionada
/// - Preço efetivo por token (usa `sellPriceCents` para venda ou
///   `pricePerTokenCents` para compra)
/// - Total a pagar/receber e, no caso de compra, o saldo restante estimado
///
/// Recebe `onConfirm` para disparar a ação final e `isLoading` para
/// indicar estado de aguardando resposta.
class BuyStepConfirm extends StatelessWidget {
  final String startupName;
  final bool isSellMode;
  final int tokenAmount;
  final int pricePerTokenCents;
  final int sellPriceCents;
  final int totalCents;
  final int walletBalance;
  final Color accentColor;
  final VoidCallback onConfirm;
  final bool isLoading;

  const BuyStepConfirm({
    super.key,
    required this.startupName,
    required this.isSellMode,
    required this.tokenAmount,
    required this.pricePerTokenCents,
    required this.sellPriceCents,
    required this.totalCents,
    required this.walletBalance,
    required this.accentColor,
    required this.onConfirm,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Define o preço efetivo usado na revisão: em vendas o usuário pode
    // ter alterado o preço (`sellPriceCents`), enquanto em compra usa-se
    // o preço da oferta/startup (`pricePerTokenCents`).
    final effectivePrice = isSellMode ? sellPriceCents : pricePerTokenCents;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cinza200),
          ),
          child: Column(
            children: [
              ConfirmRow(label: 'Startup', value: startupName),
              const ConfirmDivider(),
              ConfirmRowTokens(quantity: tokenAmount),
              const ConfirmDivider(),
              ConfirmRow(
                label: 'Preço por token',
                value: CurrencyFormatter.formatCents(effectivePrice),
              ),
              const ConfirmDivider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSellMode ? 'Você receberá' : 'Você pagará',
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCents(totalCents),
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              if (!isSellMode) ...[
                const ConfirmDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saldo após compra',
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 13,
                        color: AppColors.cinza500,
                      ),
                    ),
                    // Calcula o saldo estimado após a compra. Usa `clamp` para
                    // evitar valores negativos no texto, porém a cor indica
                    // saldo insuficiente quando `walletBalance - totalCents` é
                    // negativo.
                    Text(
                      CurrencyFormatter.formatCents(
                          (walletBalance - totalCents).clamp(0, walletBalance)),
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: walletBalance - totalCents >= 0
                            ? AppColors.azul
                            : AppColors.vermelho,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: AppPrimaryButton(
            label: isSellMode
                ? 'Confirmar ordem de venda'
                : 'Confirmar compra',
            onPressed: onConfirm,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

class BuyStepSuccess extends StatelessWidget {
  /// Tela exibida quando a operação foi concluída com sucesso.
  /// Mostra um ícone simbólico, mensagem baseada no tipo (venda/compra)
  /// e um botão para concluir (fechar/retornar ao fluxo anterior).
  final bool isSellMode;
  final VoidCallback onConcluir;

  const BuyStepSuccess({
    super.key,
    required this.isSellMode,
    required this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.azulNoite, width: 3),
          ),
          child: const Icon(Icons.currency_exchange, size: 70, color: AppColors.preto),
        ),
        const SizedBox(height: 24),
        Text(
          isSellMode ? 'Ordem de venda criada!' : 'Compra realizada!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Seu futuro se transforma e a\ninovação acelera.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 15,
            color: AppColors.cinza500,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: AppPrimaryButton(
            label: 'Concluir',
            onPressed: onConcluir,
          ),
        ),
      ],
    );
  }
}
