// Autor: Gustavo Alves de Siqueira Costa
// Data: 30/04/2026
// Descrição: Tela de detalhes de uma startup

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/startup_service.dart';
import '../../services/faq_service.dart';
import 'startup_detail_widgets.dart';
import 'startup_detail_faq.dart';
import '../profile_page.dart';
import '../balcao_page.dart';
import '../initial_page.dart';

class StartupDetailPage extends StatefulWidget {
  final String startupId;
  final String startupNome;
  final Map<String, dynamic>? usuario;

  const StartupDetailPage({
    super.key,
    required this.startupId,
    required this.startupNome,
    this.usuario,
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
    _fetchDetail();
    _loadFaqs();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialPage()),
      (_) => false,
    );
  }

  Future<void> _loadFaqs() async {
    setState(() => _faqsLoading = true);
    final result = await FaqService.getFaqs(widget.startupId);
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
    if (result != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFaqs());
    }
  }

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
    final usuario = widget.usuario ?? {};
    final nome = (usuario['nome'] ?? usuario['name']) as String? ?? '';
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          startup?['nome'] as String? ?? widget.startupNome,
          style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'perfil') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfilePage(usuario: widget.usuario),
                  ));
                } else if (value == 'sair') {
                  _logout();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'perfil', child: Text('Meu Perfil')),
                const PopupMenuItem(value: 'sair', child: Text('Sair', style: TextStyle(color: Colors.red))),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue,
                child: Text(inicial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: 1,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BalcaoNegociacaoPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 1) return;
            if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(usuario: widget.usuario),
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Em breve')),
            );
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mercado"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Carteira"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('Histórico de preços em breve',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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
                        color: selected ? Colors.blue : Colors.transparent,
                        border: Border.all(color: selected ? Colors.blue : Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _periods[i],
                        style: TextStyle(fontSize: 13, color: selected ? Colors.white : Colors.black),
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

          Center(
            child: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF disponível em breve')),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Baixar sumário executivo', style: TextStyle(color: Colors.black)),
            ),
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
                        color: selected ? Colors.blue : Colors.transparent,
                        border: Border.all(color: selected ? Colors.blue : Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _faqFilters[i],
                        style: TextStyle(fontSize: 13, color: selected ? Colors.white : Colors.black),
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
              icon: const Icon(Icons.add_comment_outlined, size: 18, color: Colors.white),
              label: const Text('Enviar pergunta', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_faqsLoading)
            const Center(child: CircularProgressIndicator(color: Colors.blue))
          else if (_faqs.isEmpty)
            Center(child: Text('Nenhuma pergunta ainda', style: TextStyle(color: Colors.grey[400])))
          else
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
                  color: isPrivada ? Colors.grey.shade200 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPrivada ? Icons.lock_outline : Icons.public,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPrivada ? 'Privada' : 'Pública',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const Spacer(),
                        Text(
                          faq['nomeUsuario'] as String? ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
              color: isSelected ? Colors.blue : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 90 : 0,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _videoUnavailable() => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text('Vídeo não disponível', style: TextStyle(color: Colors.white54))),
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
              Text(c['cargo'] as String? ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
                Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
          const Expanded(child: Divider()),
        ],
      );
}
