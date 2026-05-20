// Autor: Gustavo Alves de Siqueira Costa
// Data: 30/04/2026
// Descrição: Tela de detalhes de uma startup

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/startup_service.dart';
import 'package:mescla_invest/src/services/faq_service.dart';
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_widgets.dart';
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_faq.dart';
import 'package:mescla_invest/src/widgets/user_avatar_menu.dart';
import 'package:mescla_invest/src/widgets/app_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class StartupDetailPage extends StatefulWidget {
  final String startupId;
  final String startupNome;
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;

  const StartupDetailPage({
    super.key,
    required this.startupId,
    required this.startupNome,
    this.usuario,
    this.onTabSwitch,
  });

  @override
  State<StartupDetailPage> createState() => _StartupDetailPageState();
}

class _StartupDetailPageState extends State<StartupDetailPage> {
  Map<String, dynamic>? startup;
  bool isLoading = true;
  String? error;
  int _selectedTab = 0;
  int _selectedPeriod = 3;
  List<Map<String, dynamic>> _faqs = [];
  bool _faqsLoading = false;
  int _faqFilter = 0; // 0=Todas 1=Públicas 2=Privadas

  final List<String> _periods = ['Diário', 'Semanal', 'Mensal', '6 meses', 'YTD'];
  final List<String> _faqFilters = ['Todas', 'Públicas', 'Privadas'];

  @override
  void initState() {
    super.initState();
    // Carrega dados da startup e FAQs em paralelo ao abrir a tela.
    _fetchDetail();
    _loadFaqs();
  }

  // Busca as FAQs da startup via Cloud Function.
  // O backend filtra FAQs privadas: o usuário só vê as próprias — as de outros são excluídas.
  Future<void> _loadFaqs() async {
    setState(() => _faqsLoading = true);
    final result = await FaqService.getFaqs(widget.startupId);
    // Verifica montagem após o await — o usuário pode ter saído da tela.
    if (!mounted) return;
    setState(() {
      _faqsLoading = false;
      if (result['success'] as bool) {
        _faqs = List<Map<String, dynamic>>.from(result['data'] as List);
      }
    });
  }

  Future<void> _showFaqDialog() async {
    final result = await showDialog<FaqResult>(
      context: context,
      builder: (_) => FaqDialog(startupId: widget.startupId),
    );
    // Recarrega as FAQs após o envio. addPostFrameCallback evita chamar setState
    // durante a fase de build que ocorre imediatamente após o pop do dialog.
    if (result != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFaqs());
    }
  }

  // Busca os dados detalhados da startup (sócios, conselho, vídeo, etc.).
  Future<void> _fetchDetail() async {
    final result = await StartupService.getStartupById(widget.startupId);
    if (!mounted) return;
    setState(() {
      isLoading = false;
      if (result['success'] as bool) {
        startup = result['data'] as Map<String, dynamic>;
      } else {
        error = result['message'] as String?;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.preto),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          startup?['nome'] as String? ?? widget.startupNome,
          style: const TextStyle(color: AppColors.preto, fontSize: 22, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        actions: [
          UserAvatarMenu(
            usuario: widget.usuario,
            onPerfilTap: () {
              Navigator.pop(context);
              widget.onTabSwitch?.call(4);
            },
          ),
        ],
      ),
      body: isLoading
          ? const AppLoadingIndicator()
          : error != null
              ? Center(child: Text('Erro: $error'))
              : Column(
                  children: [
                    Expanded(child: _buildContent()),
                    const BottomActionBar(),
                  ],
                ),
    );
  }

  Widget _buildContent() {
    final data = startup!;
    final precoToken = (data['precoToken'] as num?)?.toDouble() ?? 0.0;
    final totalTokens = (data['totalTokens'] as num?)?.toInt() ?? 0;
    final descricao = data['descricao'] as String? ?? '';
    final socios = (data['socios'] as List?)
            ?.map((s) => Map<String, dynamic>.from(s as Map))
            .toList() ??
        [];
    final conselho = (data['conselho'] as List?)
            ?.map((c) => Map<String, dynamic>.from(c as Map))
            .toList() ??
        [];
    final assets = data['assets'] as Map<String, dynamic>?;
    final videoUrl = assets?['video'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          PriceRow(precoToken: precoToken),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          TokensInfo(totalTokens: totalTokens),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildTab('Dados do token', 0),
              const SizedBox(width: 24),
              _buildTab('Ofertas do balcão', 1),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cinza200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('Histórico de preços em breve',
                  style: TextStyle(color: AppColors.cinza400, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_periods.length, (i) {
                final selected = _selectedPeriod == i;
                return Padding(
                  padding: EdgeInsets.only(right: i < _periods.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.azul : AppColors.transparente,
                        border: Border.all(color: selected ? AppColors.azul : AppColors.cinza400),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _periods[i],
                        style: TextStyle(fontSize: 13, color: selected ? AppColors.branco : AppColors.preto),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 28),

          const SectionTitle(title: 'Apresentação em vídeo'),
          const SizedBox(height: 14),
          videoUrl != null ? StartupVideoPlayer(url: videoUrl) : _videoUnavailable(),
          const SizedBox(height: 20),

          Text(descricao, style: const TextStyle(fontSize: 15, height: 1.6)),
          const SizedBox(height: 20),

        // Rafael Mendes Valente - RA: 25002875
        // feat: Adicionar botão para baixar sumário executivo em PDF, se disponível
          Builder(
            builder: (context) {
              final summaryUrl = assets?['summaryUrl'] as String?;
              if (summaryUrl == null || summaryUrl.isEmpty) {
                return const SizedBox.shrink();
              }
              return Center(
                child: OutlinedButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(summaryUrl);
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    side: BorderSide(color: AppColors.cinza400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Baixar sumário executivo', style: TextStyle(color: AppColors.preto)),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          const SectionTitle(title: 'Sócios'),
          const SizedBox(height: 8),
          ...socios.map((s) => _listItem('${s['nome']} - ${s['percentual']}%')),
          const SizedBox(height: 28),

          _membrosExternosTitle(),
          const SizedBox(height: 8),
          ...conselho.map((c) => _conselhoItem(c)),
          const SizedBox(height: 28),

          const SectionTitle(title: 'Perguntas frequentes'),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_faqFilters.length, (i) {
                final selected = _faqFilter == i;
                return Padding(
                  padding: EdgeInsets.only(right: i < _faqFilters.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _faqFilter = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.azul : AppColors.transparente,
                        border: Border.all(color: selected ? AppColors.azul : AppColors.cinza400),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _faqFilters[i],
                        style: TextStyle(fontSize: 13, color: selected ? AppColors.branco : AppColors.preto),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showFaqDialog,
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

          if (_faqsLoading)
            const AppLoadingIndicator()
          else if (_faqs.isEmpty)
            Center(child: Text('Nenhuma pergunta ainda', style: TextStyle(color: AppColors.cinza400)))
          else
            // Filtra a lista no lado cliente após carregar — sem nova chamada ao backend.
            // _faqFilter: 0=Todas, 1=Públicas, 2=Privadas (apenas as do próprio usuário).
            ..._faqs.where((faq) {
              if (_faqFilter == 1) return faq['privada'] == false;
              if (_faqFilter == 2) return faq['privada'] == true;
              return true;
            }).map((faq) {
              final isPrivada = faq['privada'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPrivada ? AppColors.cinza200 : AppColors.branco,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cinza300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPrivada ? Icons.lock_outline : Icons.public,
                          size: 14,
                          color: AppColors.cinza500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPrivada ? 'Privada' : 'Pública',
                          style: TextStyle(fontSize: 12, color: AppColors.cinza500),
                        ),
                        const Spacer(),
                        Text(
                          faq['nomeUsuario'] as String? ?? '',
                          style: TextStyle(fontSize: 12, color: AppColors.cinza500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      faq['pergunta'] as String? ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? AppColors.azul : AppColors.cinza500,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 90 : 0,
            color: AppColors.azul,
          ),
        ],
      ),
    );
  }

  Widget _videoUnavailable() => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: AppColors.preto, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('Vídeo não disponível', style: TextStyle(color: AppColors.branco54))),
        ),
      );

  Widget _listItem(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 15))),
      );

  Widget _conselhoItem(Map<String, dynamic> c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Column(
            children: [
              Text(c['nome'] as String? ?? '', style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 2),
              Text(c['cargo'] as String? ?? '', style: TextStyle(fontSize: 13, color: AppColors.cinza500)),
            ],
          ),
        ),
      );

  Widget _membrosExternosTitle() => Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Membros externos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Icon(Icons.info_outline, size: 18, color: AppColors.cinza500),
              ],
            ),
          ),
          const Expanded(child: Divider()),
        ],
      );
}
