// Autor: Gustavo Alves de Siqueira Costa
// Data: 22/05/2026
// Descrição: Card de portfólio de uma startup, exibido como dialog centralizado

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/pages/home/buy_steps_page.dart';
import 'package:intl/intl.dart';

Future<void> showStartupPortfolioCard({
  required BuildContext context,
  required Map<String, dynamic> token,
  required bool saldoVisivel,
  String? logoUrl,
  Map<String, dynamic>? usuario,
  void Function(int)? onTabSwitch,
  VoidCallback? onRefresh,
}) {
  return showDialog(
    context: context,
    builder: (_) => _StartupPortfolioCard(
      token: token,
      saldoVisivel: saldoVisivel,
      logoUrl: logoUrl,
      usuario: usuario,
      onTabSwitch: onTabSwitch,
      onRefresh: onRefresh,
    ),
  );
}

class _StartupPortfolioCard extends StatefulWidget {
  final Map<String, dynamic> token;
  final bool saldoVisivel;
  final String? logoUrl;
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final VoidCallback? onRefresh;

  const _StartupPortfolioCard({
    required this.token,
    required this.saldoVisivel,
    this.logoUrl,
    this.usuario,
    this.onTabSwitch,
    this.onRefresh,
  });

  @override
  State<_StartupPortfolioCard> createState() => _StartupPortfolioCardState();
}

class _StartupPortfolioCardState extends State<_StartupPortfolioCard> {
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtQty = NumberFormat('#,##0', 'pt_BR');
  late bool _saldoVisivel;

  @override
  void initState() {
    super.initState();
    _saldoVisivel = widget.saldoVisivel;
  }

  Future<void> _handleBuy(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    final comprou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StartupDetailPage(
          startupId: widget.token['startupId'] as String? ?? '',
          startupNome: widget.token['startupNome'] as String? ?? '',
          usuario: widget.usuario,
          onTabSwitch: widget.onTabSwitch,
        ),
      ),
    );
    if (comprou == true) widget.onRefresh?.call();
  }

  Future<void> _handleSell(BuildContext dialogContext) async {
    final quantidade = (widget.token['quantidade'] as num?)?.toInt() ?? 0;
    final valorAtual = (widget.token['valorAtual'] as num?)?.toDouble() ?? 0.0;
    Navigator.of(dialogContext).pop();
    final vendeu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyStepsPage(
          startupName: widget.token['startupNome'] as String? ?? '',
          startupId: widget.token['startupId'] as String? ?? '',
          availableQuantity: quantidade,
          pricePerTokenCents: (valorAtual * 100).round(),
          isSellMode: true,
        ),
      ),
    );
    if (vendeu == true) widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.token['startupNome'] as String? ?? '—';
    final precoMedio = (widget.token['precoMedio'] as num?)?.toDouble() ?? 0.0;
    final valorAtual = (widget.token['valorAtual'] as num?)?.toDouble() ?? 0.0;
    final quantidade = (widget.token['quantidade'] as num?)?.toInt() ?? 0;
    final precoAnterior =
        (widget.token['precoAnterior'] as num?)?.toDouble() ?? valorAtual;
    final totalAtual = valorAtual * quantidade;
    final totalInvestido = precoMedio * quantidade;
    final variacaoPct =
        precoMedio > 0 ? (valorAtual - precoMedio) / precoMedio * 100 : 0.0;
    final variacaoLabel =
        'Retorno ${variacaoPct >= 0 ? '+' : ''}${variacaoPct.toStringAsFixed(1)}%';
    final accentColor = variacaoPct > 0 ? AppColors.verde : variacaoPct < 0 ? AppColors.vermelho : AppColors.cinza400;
    final diariaPct = precoAnterior > 0
        ? (valorAtual - precoAnterior) / precoAnterior * 100
        : 0.0;
    final diariaLabel =
        'Hoje ${diariaPct >= 0 ? '+' : ''}${diariaPct.toStringAsFixed(1)}%';
    final diariaColor = diariaPct > 0 ? AppColors.verde : diariaPct < 0 ? AppColors.vermelho : AppColors.cinza400;

    return Dialog(
      backgroundColor: AppColors.branco,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: logo + nome + badge retorno + pill tokens + olho
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  backgroundImage: widget.logoUrl != null
                      ? NetworkImage(widget.logoUrl!)
                      : null,
                  child: widget.logoUrl == null
                      ? Icon(Icons.business, color: accentColor, size: 22)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          variacaoLabel,
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _saldoVisivel = !_saldoVisivel),
                      child: Icon(
                        _saldoVisivel
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.cinza500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.azul.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.toll_outlined,
                              size: 12, color: AppColors.azul),
                          const SizedBox(width: 3),
                          Text(
                            '${_fmtQty.format(quantidade)} tokens',
                            style: const TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azul,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.cinza200),
            const SizedBox(height: 14),

            // Stats linha 1
            Row(
              children: [
                _Stat(
                  label: 'Valor investido',
                  value: _saldoVisivel ? _fmt.format(totalInvestido) : '••••••',
                ),
                Container(width: 1, height: 32, color: AppColors.cinza200),
                _Stat(
                  label: 'Portfólio total',
                  value: _saldoVisivel ? _fmt.format(totalAtual) : '••••••',
                  valueColor: accentColor,
                  alignEnd: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stats linha 2
            Row(
              children: [
                _Stat(
                  label: 'Preço médio pago',
                  value: _fmt.format(precoMedio),
                ),
                Container(width: 1, height: 32, color: AppColors.cinza200),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Preço de mercado',
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 11,
                          color: AppColors.cinza500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: diariaColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              diariaLabel,
                              style: TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: diariaColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _fmt.format(valorAtual),
                            style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: diariaColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Botões
            Builder(
              builder: (dialogContext) => Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleSell(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cinza200,
                        foregroundColor: AppColors.preto,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.cinza400),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Vender',
                          style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleBuy(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azul,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: const Text('Comprar mais',
                          style: TextStyle(
                              color: AppColors.branco,
                              fontFamily: 'JosefinSans',
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  const _Stat({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 11,
              color: AppColors.cinza500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
