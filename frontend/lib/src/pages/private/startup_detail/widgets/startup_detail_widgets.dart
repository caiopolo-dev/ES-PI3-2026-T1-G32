// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Widgets reutilizáveis da tela de detalhes de startup

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

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
                  Text('Variação do dia', style: TextStyle(fontSize: 14, color: AppColors.cinza700)),
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
                        color: valorizacaoPercentual > 0
                          ? AppColors.verde
                          : valorizacaoPercentual < 0
                              ? AppColors.vermelho
                              : AppColors.preto,
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
                    child: AppSecondaryButton(
                      label: 'Vender',
                      onPressed: onVender,
                      verticalPadding: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: double.infinity,
                  child: AppPrimaryButton(
                    label: 'Comprar',
                    onPressed: onComprar,
                    verticalPadding: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class FaqCard extends StatelessWidget {
  final Map<String, dynamic> faq;
  const FaqCard({super.key, required this.faq});

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(fontSize: 12, color: AppColors.cinza500),
              ),
              const Spacer(),
              Text(
                faq['nomeUsuario'] as String? ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.cinza500),
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
  }
}

class PeriodSelectorRow extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  const PeriodSelectorRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = selected == i;
          return Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.azul : AppColors.transparente,
                  border: Border.all(
                    color: isSelected ? AppColors.azul : AppColors.cinza400,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? AppColors.branco : AppColors.preto,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StartupVideoUnavailable extends StatelessWidget {
  const StartupVideoUnavailable({super.key});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.preto,
              borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text('Vídeo não disponível',
                style: TextStyle(color: AppColors.branco54)),
          ),
        ),
      );
}

class StartupListItem extends StatelessWidget {
  final String text;
  const StartupListItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
            child: Text(text, style: const TextStyle(fontSize: 15))),
      );
}

class StartupConselhoItem extends StatelessWidget {
  final Map<String, dynamic> membro;
  const StartupConselhoItem({super.key, required this.membro});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Column(
            children: [
              Text(membro['nome'] as String? ?? '',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 2),
              Text(membro['cargo'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.cinza500)),
            ],
          ),
        ),
      );
}

class StartupMembrosExternosTitle extends StatelessWidget {
  const StartupMembrosExternosTitle({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Membros externos',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Icon(Icons.info_outline,
                    size: 18, color: AppColors.cinza500),
              ],
            ),
          ),
          const Expanded(child: Divider()),
        ],
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
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
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
