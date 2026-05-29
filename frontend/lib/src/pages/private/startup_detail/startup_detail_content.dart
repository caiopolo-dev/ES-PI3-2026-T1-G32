// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widget de conteúdo scrollável da tela de detalhes de startup

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/startup_detail_types.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/widgets/startup_detail_widgets.dart';

class StartupDetailContent extends StatelessWidget {
  final Map<String, dynamic> startup;
  final bool priceHistoryLoading;
  final List<Map<String, dynamic>> priceHistory;
  final PriceHistoryPeriod selectedPeriod;
  final String? videoUrl;
  final String? summaryUrl;
  final int userTokenQuantity;
  final bool faqsLoading;
  final List<Map<String, dynamic>> faqs;
  final FaqFilter faqFilter;
  final double valorizacaoPercentual;
  final List<String> periods;
  final List<String> faqFilterLabels;
  final VoidCallback onFaqDialogOpen;
  final ValueChanged<int> onPeriodChanged;
  final ValueChanged<int> onFaqFilterChanged;
  final Future<void> Function()? onRefresh;

  const StartupDetailContent({
    super.key,
    required this.startup,
    required this.priceHistoryLoading,
    required this.priceHistory,
    required this.selectedPeriod,
    this.videoUrl,
    this.summaryUrl,
    required this.userTokenQuantity,
    required this.faqsLoading,
    required this.faqs,
    required this.faqFilter,
    required this.valorizacaoPercentual,
    required this.periods,
    required this.faqFilterLabels,
    required this.onFaqDialogOpen,
    required this.onPeriodChanged,
    required this.onFaqFilterChanged,
    this.onRefresh,
  });

  DateTime? _converterDataHistorico(String? dataTexto) {
    if (dataTexto == null || dataTexto.isEmpty) return null;
    final data = DateTime.tryParse(dataTexto);
    if (data == null) return null;
    // Firestore vem em UTC. Brasil = UTC-3.
    return data.toUtc().subtract(const Duration(hours: 3));
  }

  List<Map<String, dynamic>> _historicoFiltradoPorPeriodo() {
    if (priceHistory.isEmpty) return [];
    final agora = DateTime.now();
    DateTime dataInicial;
    switch (selectedPeriod) {
      case PriceHistoryPeriod.oneDay:
        dataInicial = DateTime(agora.year, agora.month, agora.day);
      case PriceHistoryPeriod.sevenDays:
        dataInicial = agora.subtract(const Duration(days: 7));
      case PriceHistoryPeriod.oneMonth:
        dataInicial = agora.subtract(const Duration(days: 30));
      case PriceHistoryPeriod.sixMonths:
        dataInicial = DateTime(agora.year, agora.month - 6, agora.day);
      case PriceHistoryPeriod.oneYear:
        dataInicial = DateTime(agora.year, 1, 1);
      case PriceHistoryPeriod.all:
        return List.from(priceHistory);
    }
    return priceHistory.where((item) {
      final data = _converterDataHistorico(item['createdAt']?.toString());
      if (data == null) return false;
      return data.isAfter(dataInicial);
    }).toList();
  }

  List<FlSpot> _pontosGrafico() {
    final historico = _historicoFiltradoPorPeriodo();
    return List.generate(historico.length, (index) {
      final precoCentavos = (historico[index]['price'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), precoCentavos / 100);
    });
  }

  List<String> _labelsGrafico() {
    final historico = _historicoFiltradoPorPeriodo();
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return historico.map((item) {
      final dataLocal = _converterDataHistorico(item['createdAt']?.toString());
      if (dataLocal == null) return '';
      if (selectedPeriod == PriceHistoryPeriod.oneDay) {
        return '${dataLocal.hour.toString().padLeft(2, '0')}:${dataLocal.minute.toString().padLeft(2, '0')}';
      }
      if (selectedPeriod == PriceHistoryPeriod.sixMonths || selectedPeriod == PriceHistoryPeriod.oneYear || selectedPeriod == PriceHistoryPeriod.all) {
        return meses[dataLocal.month - 1];
      }
      return '${dataLocal.day}/${dataLocal.month}';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final precoToken = ((startup['precoToken'] as num?)?.toDouble() ?? 0.0) / 100;
    final totalTokens = (startup['totalTokens'] as num?)?.toInt() ?? 0;
    final tokensDisponiveis = (startup['tokensDisponiveis'] as num?)?.toInt() ?? 0;
    final descricao = startup['descricao'] as String? ?? '';
    final socios = (startup['socios'] as List?)
            ?.map((s) => Map<String, dynamic>.from(s as Map))
            .toList() ?? [];
    final conselho = (startup['conselho'] as List?)
            ?.map((c) => Map<String, dynamic>.from(c as Map))
            .toList() ?? [];

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          PriceRow(
            precoToken: precoToken,
            valorizacaoPercentual: valorizacaoPercentual,
            valorizacaoLoading: priceHistoryLoading,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          TokensInfo(totalTokens: totalTokens, tokensDisponiveis: tokensDisponiveis),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 36),
          priceHistoryLoading
              ? Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cinza200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: AppLoadingIndicator()),
                )
              : Builder(builder: (context) {
                  final pontos = _pontosGrafico();
                  final cor = pontos.length >= 2
                      ? pontos.last.y > pontos.first.y
                          ? AppColors.verde
                          : pontos.last.y < pontos.first.y
                              ? AppColors.vermelho
                              : AppColors.preto
                      : AppColors.preto;
                  return GraficoLinha(
                    pontos: pontos,
                    labelsInferiores: _labelsGrafico(),
                    formatarValorEsquerda: (valor) => 'R\$ ${valor.toStringAsFixed(2)}',
                    cor: cor,
                  );
                }),
          const SizedBox(height: 14),
          PeriodSelectorRow(
            labels: periods,
            selected: selectedPeriod.index,
            onSelected: onPeriodChanged,
          ),
          const SizedBox(height: 28),
          const SectionTitle(title: 'Apresentação em vídeo'),
          const SizedBox(height: 14),
          videoUrl != null
              ? StartupVideoPlayer(url: videoUrl!)
              : const StartupVideoUnavailable(),
          const SizedBox(height: 20),
          Text(descricao, style: const TextStyle(fontSize: 15, height: 1.6)),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final url = summaryUrl;
              if (url == null || url.isEmpty) return const SizedBox.shrink();
              return Center(
                child: AppOutlineButton(
                  label: 'Acessar sumário executivo',
                  borderRadius: 8,
                  onPressed: () async {
                    final uri = Uri.tryParse(url);
                    if (uri == null) return;
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Não foi possível abrir o PDF')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const SectionTitle(title: 'Sócios'),
          const SizedBox(height: 8),
          ...socios.map((s) => StartupListItem(text: '${s['nome']} - ${s['percentual']}%')),
          const SizedBox(height: 28),
          const StartupMembrosExternosTitle(),
          const SizedBox(height: 8),
          ...conselho.map((c) => StartupConselhoItem(membro: c)),
          const SizedBox(height: 28),
          const SectionTitle(title: 'Perguntas frequentes'),
          const SizedBox(height: 16),
          PeriodSelectorRow(
            labels: userTokenQuantity > 0 ? faqFilterLabels : faqFilterLabels.sublist(0, 2),
            selected: faqFilter.index,
            onSelected: onFaqFilterChanged,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onFaqDialogOpen,
              icon: const Icon(Icons.add_comment_outlined, size: 18, color: AppColors.branco),
              label: const Text('Enviar pergunta', style: TextStyle(color: AppColors.branco)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azul,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (faqsLoading)
            const AppLoadingIndicator()
          else if (faqs.isEmpty)
            Center(child: Text('Nenhuma pergunta ainda', style: TextStyle(color: AppColors.cinza400)))
          else
            ...faqs.where((faq) {
              if (faqFilter == FaqFilter.publicas) return faq['privada'] == false;
              if (faqFilter == FaqFilter.privadas) return faq['privada'] == true;
              return true;
            }).map((faq) => FaqCard(faq: faq)),
          const SizedBox(height: 32),
        ],
      ),
    ),
    );
  }
}
