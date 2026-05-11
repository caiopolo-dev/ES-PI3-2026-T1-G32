// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Widgets reutilizáveis da tela de detalhes de startup

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:mescla_invest/src/services/storage_service.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

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

class PriceRow extends StatelessWidget {
  final double precoToken;
  const PriceRow({super.key, required this.precoToken});

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

class TokensInfo extends StatelessWidget {
  final int totalTokens;
  const TokensInfo({super.key, required this.totalTokens});

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

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key});

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

class StartupVideoPlayer extends StatefulWidget {
  final String url;
  const StartupVideoPlayer({super.key, required this.url});

  @override
  State<StartupVideoPlayer> createState() => _StartupVideoPlayerState();
}

class _StartupVideoPlayerState extends State<StartupVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Inicia a resolução da URL e inicialização do player ao montar o widget.
    _resolveAndInit(widget.url);
  }

  // Converte a URL de armazenamento (gs://) para HTTPS e inicializa o VideoPlayerController.
  // O VideoPlayerController só aceita HTTPS — gs:// é o formato interno do Firebase Storage.
  Future<void> _resolveAndInit(String url) async {
    try {
      // Converte o gs:// do Firestore para uma URL HTTPS com token de acesso.
      final downloadUrl = await StorageService.getDownloadUrl(url);
      final controller = VideoPlayerController.networkUrl(Uri.parse(downloadUrl));
      await controller.initialize();
      // Se o widget foi destruído durante o await, descarta o controller para evitar leak.
      if (!mounted) { controller.dispose(); return; }
      setState(() { _controller = controller; _initialized = true; });
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    // Libera os recursos do player de vídeo ao sair da tela.
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
