// Autor: Gustavo Alves de Siqueira Costa
// Data: 22/05/2026
// Descrição: Tela de detalhes do portfólio de uma startup específica

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/pages/home/buy_steps_page.dart';
import 'package:intl/intl.dart';

class StartupPortfolioDetailPage extends StatefulWidget {
  final Map<String, dynamic> token;
  final List<Map<String, dynamic>> purchases;
  final String? logoUrl;
  final bool saldoVisivel;
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;

  const StartupPortfolioDetailPage({
    super.key,
    required this.token,
    required this.purchases,
    required this.saldoVisivel,
    this.logoUrl,
    this.usuario,
    this.onTabSwitch,
  });

  @override
  State<StartupPortfolioDetailPage> createState() =>
      _StartupPortfolioDetailPageState();
}

class _StartupPortfolioDetailPageState
    extends State<StartupPortfolioDetailPage> {
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtQty = NumberFormat('#,##0', 'pt_BR');

  Future<void> _handleBuy() async {
    final startupId = widget.token['startupId'] as String? ?? '';
    final startupNome = widget.token['startupNome'] as String? ?? '';
    final comprou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StartupDetailPage(
          startupId: startupId,
          startupNome: startupNome,
          usuario: widget.usuario,
          onTabSwitch: widget.onTabSwitch,
        ),
      ),
    );
    if (comprou == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _handleSell() async {
    final startupId = widget.token['startupId'] as String? ?? '';
    final startupNome = widget.token['startupNome'] as String? ?? '';
    final quantidade = (widget.token['quantidade'] as num?)?.toInt() ?? 0;
    final valorAtual = (widget.token['valorAtual'] as num?)?.toDouble() ?? 0.0;
    final pricePerTokenCents = (valorAtual * 100).round();

    final vendeu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyStepsPage(
          startupName: startupNome,
          startupId: startupId,
          availableQuantity: quantidade,
          pricePerTokenCents: pricePerTokenCents,
          isSellMode: true,
        ),
      ),
    );
    if (vendeu == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.token['startupNome'] as String? ?? '—';
    final precoMedio = (widget.token['precoMedio'] as num?)?.toDouble() ?? 0.0;
    final valorAtual = (widget.token['valorAtual'] as num?)?.toDouble() ?? 0.0;
    final quantidade = (widget.token['quantidade'] as num?)?.toInt() ?? 0;

    final totalAtual = valorAtual * quantidade;
    final totalInvestido = precoMedio * quantidade;
    final positivo = valorAtual >= precoMedio;
    final variacaoPct =
        precoMedio > 0 ? (valorAtual - precoMedio) / precoMedio * 100 : 0.0;
    final variacaoLabel =
        '${variacaoPct >= 0 ? '+' : ''}${variacaoPct.toStringAsFixed(1)}%';
    final accentColor = positivo ? AppColors.verde : AppColors.vermelho;

    return Scaffold(
      backgroundColor: AppColors.cinza100,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.preto),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          nome,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: kBottomNavigationBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.branco,
            border: Border(top: BorderSide(color: AppColors.cinza200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleSell,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppColors.verde),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Vender',
                        style: TextStyle(
                            color: AppColors.verde, fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azul,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: const Text('Comprar mais',
                        style:
                            TextStyle(color: AppColors.branco, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Cartão de resumo do portfólio
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cinza200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: accentColor.withValues(alpha: 0.1),
                        backgroundImage: widget.logoUrl != null
                            ? NetworkImage(widget.logoUrl!)
                            : null,
                        child: widget.logoUrl == null
                            ? Icon(Icons.business,
                                color: accentColor, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                variacaoLabel,
                                style: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.azul.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.toll_outlined,
                                size: 13, color: AppColors.azul),
                            const SizedBox(width: 4),
                            Text(
                              '${_fmtQty.format(quantidade)} tokens',
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
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppColors.cinza200),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _PortfolioStat(
                        label: 'Portfólio total',
                        value: widget.saldoVisivel
                            ? _fmt.format(totalAtual)
                            : '••••••',
                        valueColor: accentColor,
                      ),
                      Container(
                          width: 1, height: 36, color: AppColors.cinza200),
                      _PortfolioStat(
                        label: 'Valor investido',
                        value: widget.saldoVisivel
                            ? _fmt.format(totalInvestido)
                            : '••••••',
                        alignEnd: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _PortfolioStat(
                        label: 'Preço atual (mercado)',
                        value: _fmt.format(valorAtual),
                        valueColor: accentColor,
                      ),
                      Container(
                          width: 1, height: 36, color: AppColors.cinza200),
                      _PortfolioStat(
                        label: 'Preço médio pago',
                        value: _fmt.format(precoMedio),
                        alignEnd: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Título da seção de compras
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Compras realizadas (${widget.purchases.length})',
                style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          widget.purchases.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nenhuma compra registrada',
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          color: AppColors.cinza500,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PurchaseCard(
                      tx: widget.purchases[index],
                      saldoVisivel: widget.saldoVisivel,
                      fmt: _fmt,
                      fmtQty: _fmtQty,
                    ),
                    childCount: widget.purchases.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool saldoVisivel;
  final NumberFormat fmt;
  final NumberFormat fmtQty;

  const _PurchaseCard({
    required this.tx,
    required this.saldoVisivel,
    required this.fmt,
    required this.fmtQty,
  });

  @override
  Widget build(BuildContext context) {
    final txQty = (tx['quantity'] as num?)?.toInt() ?? 0;
    final txTotal =
        ((tx['totalCents'] as num?)?.toDouble() ?? 0) / 100;
    final txPreco =
        ((tx['pricePerTokenCents'] as num?)?.toDouble() ?? 0) / 100;
    final dataStr = tx['createdAt'] != null
        ? DateFormat('dd/MM/yyyy · HH:mm')
            .format(DateTime.parse(tx['createdAt'] as String))
        : '—';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinza200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dataStr,
                style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 12,
                  color: AppColors.cinza500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.azul.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.toll_outlined,
                        size: 13, color: AppColors.azul),
                    const SizedBox(width: 4),
                    Text(
                      '${fmtQty.format(txQty)} tokens',
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
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.cinza200),
          const SizedBox(height: 10),
          Row(
            children: [
              _PortfolioStat(
                label: 'Gasto nesta compra',
                value: saldoVisivel ? fmt.format(txTotal) : '••••••',
              ),
              Container(width: 1, height: 36, color: AppColors.cinza200),
              _PortfolioStat(
                label: 'Preço por token',
                value: fmt.format(txPreco),
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  const _PortfolioStat({
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
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
