// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Widgets reutilizáveis da tela de detalhes de startup

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
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
  final double valorizacaoPercentual;
  final bool valorizacaoLoading;

  const PriceRow({
    super.key,
    required this.precoToken,
    required this.valorizacaoPercentual,
    this.valorizacaoLoading = false,
  });

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preço agora', style: TextStyle(fontSize: 14, color: AppColors.cinza700)),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(precoToken)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            VerticalDivider(color: AppColors.cinza300, thickness: 1, width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Valorização', style: TextStyle(fontSize: 14, color: AppColors.cinza700)),
                  const SizedBox(height: 4),
                  if (valorizacaoLoading)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cinza400,
                      ),
                    )
                  else
                    Text(
                      '${valorizacaoPercentual >= 0 ? '+' : ''}${NumberFormat('#,##0.00', 'pt_BR').format(valorizacaoPercentual)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: valorizacaoPercentual >= 0
                            ? AppColors.verde
                            : AppColors.vermelho,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}



class TokensInfo extends StatelessWidget {
  final int totalTokens;
  final int tokensDisponiveis;
  const TokensInfo({super.key, required this.totalTokens, required this.tokensDisponiveis});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tokens em circulação', style: TextStyle(fontSize: 14, color: AppColors.cinza700)),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat('#,##0', 'pt_BR').format(totalTokens),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            VerticalDivider(color: AppColors.cinza300, thickness: 1, width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Tokens disponíveis', style: TextStyle(fontSize: 14, color: AppColors.cinza700)),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat('#,##0', 'pt_BR').format(tokensDisponiveis),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    this.onComprar,
    this.onVender,
    this.temTokens = false,
  });

  final VoidCallback? onComprar;
  final VoidCallback? onVender;
  final bool temTokens;

  @override
  Widget build(BuildContext context) => SafeArea(
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
              if (temTokens) ...[
                Expanded(
                  child: SizedBox(
                    height: double.infinity,
                    child: OutlinedButton(
                      onPressed: onVender,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: AppColors.vermelho),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Vender', style: TextStyle(color: AppColors.vermelho, fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  child: ElevatedButton(
                    onPressed: onComprar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azul,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: const Text('Comprar', style: TextStyle(color: AppColors.branco, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: AppColors.preto),
            if (_hasError)
              Text('Erro ao carregar vídeo', style: TextStyle(color: AppColors.branco54))
            else if (_initialized)
              VideoPlayer(_controller!)
            else
              const CircularProgressIndicator(color: AppColors.branco),
            if (_initialized)
              GestureDetector(
                onTap: () => setState(() {
                  _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                }),
                child: AnimatedOpacity(
                  opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.play_circle_outline, color: AppColors.branco, size: 64),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
