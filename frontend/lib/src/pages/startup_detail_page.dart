// Autor: Gustavo Alves de Siqueira Costa
// Data: 30/04/2026
// Descrição: Tela de detalhes de uma startup

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/startup_service.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'profile_page.dart';
import 'balcao_page.dart';
import 'initial_page.dart';

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

  final List<String> _periods = ['Diário', 'Semanal', 'Mensal', '6 meses', 'YTD'];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
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
                    const _BottomActionBar(),
                  ],
                ),
    );
  }

  Widget _buildContent() {
    final data = startup!;
    final precoToken = (data['precoToken'] as num?)?.toDouble() ?? 0.0;
    final totalTokens = (data['totalTokens'] as num?)?.toInt() ?? 0;
    final descricao = data['descricao'] as String? ?? '';
    final socios = (data['socios'] as List?)?.map((s) => Map<String, dynamic>.from(s as Map)).toList() ?? [];
    final conselho = (data['conselho'] as List?)?.map((c) => Map<String, dynamic>.from(c as Map)).toList() ?? [];
    final assets = data['assets'] as Map<String, dynamic>?;
    final videoUrl = assets?['video'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _PriceRow(precoToken: precoToken),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _TokensInfo(totalTokens: totalTokens),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              _buildTab('Dados do token', 0),
              const SizedBox(width: 24),
              _buildTab('Ofertas do balcão', 1),
            ],
          ),
          const SizedBox(height: 20),

          // Gráfico placeholder
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

          // Filtros de período
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

          const _SectionTitle(title: 'Apresentação em vídeo'),
          const SizedBox(height: 14),
          videoUrl != null ? _VideoPlayer(url: videoUrl) : _videoUnavailable(),
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

          const _SectionTitle(title: 'Sócios'),
          const SizedBox(height: 8),
          ...socios.map((s) => _listItem('${s['nome']} - ${s['percentual']}%')),
          const SizedBox(height: 28),

          _membrosExternosTitle(),
          const SizedBox(height: 8),
          ...conselho.map((c) => _conselhoItem(c)),
          const SizedBox(height: 28),
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

// --- Widgets reutilizáveis ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Expanded(child: Divider()),
        ],
      );
}

class _PriceRow extends StatelessWidget {
  final double precoToken;
  const _PriceRow({required this.precoToken});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preço agora', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(precoToken)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            VerticalDivider(color: Colors.grey[300], thickness: 1, width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Variação Hoje', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('—', style: TextStyle(fontSize: 22, color: Colors.grey[400])),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TokensInfo extends StatelessWidget {
  final int totalTokens;
  const _TokensInfo({required this.totalTokens});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('Tokens em circulação', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            NumberFormat('#,##0', 'pt_BR').format(totalTokens),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      );
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Vender', style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Comprar', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
}

// --- Player de vídeo ---

class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolveAndInit(widget.url);
  }

  Future<String> _toDownloadUrl(String url) async {
    if (url.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(url).getDownloadURL();
    }
    if (url.startsWith('https://storage.googleapis.com/')) {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final bucket = segments[0];
        final path = segments.sublist(1).join('/');
        return FirebaseStorage.instance.refFromURL('gs://$bucket/$path').getDownloadURL();
      }
    }
    return url;
  }

  Future<void> _resolveAndInit(String url) async {
    try {
      final downloadUrl = await _toDownloadUrl(url);
      final controller = VideoPlayerController.networkUrl(Uri.parse(downloadUrl));
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      setState(() { _controller = controller; _initialized = true; });
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: Colors.black),
            if (_hasError)
              const Text('Erro ao carregar vídeo', style: TextStyle(color: Colors.white54))
            else if (_initialized)
              VideoPlayer(_controller!)
            else
              const CircularProgressIndicator(color: Colors.white),
            if (_initialized)
              GestureDetector(
                onTap: () => setState(() {
                  _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                }),
                child: AnimatedOpacity(
                  opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
