// Autor: Caio Ferreira Polo
// Descrição: Tela de compra de tokens em etapas (seleção de quantidade, revisão e confirmação)
import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/token_data_service.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/pages/private/buy_steps/widgets/buy_steps_widgets.dart';
import 'package:mescla_invest/src/pages/private/buy_steps/widgets/buy_selection_widgets.dart';
import 'package:mescla_invest/src/pages/private/buy_steps/widgets/buy_confirm_widgets.dart';
import 'package:mescla_invest/src/utils/currency_formatter.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

/// Página que conduz o usuário pelo fluxo de compra/venda em 3 passos:
/// 0) Seleção de quantidade / preço
/// 1) Revisão / confirmação
/// 2) Resultado (sucesso)
///
/// A mesma página suporta modo de venda (`isSellMode`) e fluxo de
/// startup (`isStartupFlow`). Recebe parâmetros essenciais como preço,
/// quantidade disponível e identificadores de oferta/startup quando
/// aplicáveis.
class BuyStepsPage extends StatefulWidget {
  @override
  State<BuyStepsPage> createState() => _BuyStepsPageState();

  final String startupName;
  final int availableQuantity;
  final int pricePerTokenCents;
  final String? offerId;
  final String? startupId;
  final bool isStartupFlow;
  final bool isSellMode;

  const BuyStepsPage({
    super.key,
    required this.startupName,
    required this.availableQuantity,
    required this.pricePerTokenCents,
    this.offerId,
    this.startupId,
    this.isStartupFlow = false,
    this.isSellMode = false,
  });
}

/// Estado que controla o passo atual, valores temporários (quantidade,
/// preço de venda), validações e chamadas a services para executar a
/// compra/venda. Mantém `walletBalance` para validar saldo quando for
/// necessário e usa `mounted` antes de atualizar o estado em callbacks
/// assíncronos.
class _BuyStepsPageState extends State<BuyStepsPage> {
  int currentStep = 0;
  bool isLoading = false;
  String errorText = '';

  int tokenAmount = 1;
  int walletBalance = 0;
  int _sellPriceCents = 0;
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  late final TextEditingController _priceController;
  late final FocusNode _quantityFocus;
  late final FocusNode _priceFocus;

  List<String> get _stepTitles => widget.isSellMode
      ? ['Venda de token', 'Confirmação de venda', 'Ordem criada']
      : ['Compra de token', 'Confirmação de compra', 'Compra concluída'];

  /// Carrega o saldo atual da carteira do usuário via `TokenDataService`.
  /// Usa `mounted` para evitar setState depois que o widget foi descartado.
  Future<void> loadWalletBalance() async {
    final balance = await TokenDataService.getWalletBalance();
    if (!mounted) return;
    setState(() => walletBalance = balance);
  }

    /// Total em centavos para a operação atual.
    /// Se estiver em modo venda (`isSellMode`) considera `_sellPriceCents`,
    /// caso contrário usa `widget.pricePerTokenCents` (preço da oferta/startup).
    int get totalCents =>
      tokenAmount *
      (widget.isSellMode ? _sellPriceCents : widget.pricePerTokenCents);

  void tokenSum() {
    if (tokenAmount < widget.availableQuantity) {
      setState(() {
        tokenAmount++;
        _quantityController.text = tokenAmount.toString();
      });
    }
  }

  void tokenSub() {
    if (tokenAmount > 1) {
      setState(() {
        tokenAmount--;
        _quantityController.text = tokenAmount.toString();
      });
    }
  }

  /// Executa a confirmação final da compra/venda.
  ///
  /// Comportamento:
  /// - Define `isLoading` enquanto a chamada de rede acontece.
  /// - Dependendo do modo, chama o service apropriado:
  ///   * venda -> `WalletService.createSellOffer`
  ///   * startup -> `TokenDataService.buyStartupToken`
  ///   * oferta -> `TokenDataService.buyOffer`
  /// - Em caso de sucesso avança para o passo de resultado, senão mostra
  ///   a mensagem de erro retornada pelo service.
  Future<void> confirmPurchase() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    Map<String, dynamic> result;

    if (widget.isSellMode) {
      if (widget.startupId == null || widget.startupId!.isEmpty) {
        setState(() {
          isLoading = false;
          errorText = 'ID da startup não informado.';
        });
        return;
      }
      result = await WalletService.createSellOffer(
        startupId: widget.startupId!,
        quantity: tokenAmount,
        pricePerTokenCents: _sellPriceCents,
      );
    } else if (widget.isStartupFlow) {
      if (widget.startupId == null || widget.startupId!.isEmpty) {
        setState(() {
          isLoading = false;
          errorText = 'ID da startup não informado.';
        });
        return;
      }
      result = await TokenDataService.buyStartupToken(
        startupId: widget.startupId!,
        quantity: tokenAmount,
      );
    } else {
      if (widget.offerId == null || widget.offerId!.isEmpty) {
        setState(() {
          isLoading = false;
          errorText = 'ID da oferta não informado.';
        });
        return;
      }
      result = await TokenDataService.buyOffer(
        offerId: widget.offerId!,
        quantity: tokenAmount,
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] == true) {
      setState(() => currentStep = 2);
    } else {
      setState(() => errorText = result['message'] ?? 'Erro ao confirmar');
    }
  }

  @override
  void initState() {
    super.initState();
    _sellPriceCents =
        widget.pricePerTokenCents > 0 ? widget.pricePerTokenCents : 100;
    _priceController = TextEditingController(
      text: CurrencyFormatter.formatCents(_sellPriceCents),
    );
    _quantityFocus = FocusNode()
      ..addListener(() {
        if (!_quantityFocus.hasFocus && tokenAmount < 1) {
          setState(() {
            tokenAmount = 1;
            _quantityController.text = '1';
          });
        }
      });
    _priceFocus = FocusNode()
      ..addListener(() {
        if (!_priceFocus.hasFocus && _sellPriceCents < 1) {
          setState(() {
            _sellPriceCents = 1;
            _priceController.text = CurrencyFormatter.formatCents(1);
          });
        }
      });
    loadWalletBalance();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _quantityFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  /// Valida os dados do passo atual. Retorna `true` se tudo estiver ok,
  /// caso contrário atualiza `errorText` com a mensagem apropriada.
  bool validateStep() {
    setState(() => errorText = '');
    switch (currentStep) {
      case 0:
        if (tokenAmount <= 0) {
          setState(
              () => errorText = 'Selecione pelo menos 1 token para continuar.');
          return false;
        }
        if (tokenAmount > widget.availableQuantity) {
          setState(() => errorText = 'Quantidade maior que a disponível.');
          return false;
        }
        if (widget.isSellMode &&
            (_sellPriceCents < 1 || _sellPriceCents > 5000000)) {
          setState(() => errorText =
              'Preço inválido. Use entre R\$ 0,01 e R\$ 50.000,00.');
          return false;
        }
        if (!widget.isSellMode && totalCents > walletBalance) {
          setState(() => errorText = 'Saldo insuficiente para esta compra.');
          return false;
        }
        return true;
      case 1:
      case 2:
        return true;
      default:
        return false;
    }
  }

  /// Avança para o próximo passo se a validação atual passar. Se já estiver
  /// no último passo, fecha a tela retornando `true` para o chamador.
  void nextStep() {
    if (!validateStep()) return;
    if (currentStep < 2) {
      setState(() => currentStep++);
    } else {
      Navigator.pop(context, true);
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accentColor =
        widget.isSellMode ? AppColors.verde : AppColors.azul;

    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.preto),
          onPressed: () {
            if (currentStep == 0) {
              Navigator.pop(context);
            } else if (currentStep == 2) {
              Navigator.pop(context, true);
            } else {
              setState(() => currentStep--);
            }
          },
        ),
        title: Text(
          widget.startupName,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.preto,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepProgressBar(
                currentStep: currentStep,
                totalSteps: 3,
                color: accentColor,
              ),

              Text(
                _stepTitles[currentStep],
                style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 14,
                  color: AppColors.cinza500,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(child: _buildStepContent(accentColor)),

              if (errorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.vermelho),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          errorText,
                          style: const TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 12,
                            color: AppColors.vermelho,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(Color accentColor) {
    switch (currentStep) {
      case 0:
        return _buildStep0(accentColor);
      case 1:
        return _buildStep1(accentColor);
      case 2:
        return _buildStep2(accentColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Seleção de quantidade ─────────────────────────────────────────
  Widget _buildStep0(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BuyInfoCard(
          isSellMode: widget.isSellMode,
          availableQuantity: widget.availableQuantity,
          walletBalance: walletBalance,
          pricePerTokenCents: widget.pricePerTokenCents,
          accentColor: accentColor,
        ),

        if (widget.isSellMode) ...[
          const SizedBox(height: 12),
          BuyPriceField(
            controller: _priceController,
            focusNode: _priceFocus,
            accentColor: accentColor,
            onChanged: (value) {
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.isEmpty) {
                setState(() => _sellPriceCents = 0);
                return;
              }
              final cents = int.tryParse(digits) ?? 0;
              setState(() => _sellPriceCents = cents.clamp(0, 5000000));
            },
          ),
        ],

        const Spacer(),

        const Text(
          'Quantidade de tokens',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        BuyQuantitySelector(
          controller: _quantityController,
          focusNode: _quantityFocus,
          accentColor: accentColor,
          availableQuantity: widget.availableQuantity,
          onSub: tokenSub,
          onSum: tokenSum,
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() => tokenAmount = 0);
              return;
            }
            final parsed = int.tryParse(value) ?? 0;
            if (parsed > widget.availableQuantity) {
              setState(() {
                tokenAmount = widget.availableQuantity;
                _quantityController.text = tokenAmount.toString();
                _quantityController.selection = TextSelection.collapsed(
                    offset: _quantityController.text.length);
              });
            } else {
              setState(() => tokenAmount = parsed);
            }
          },
        ),

        const SizedBox(height: 20),

        BuyTotalCard(
          isSellMode: widget.isSellMode,
          totalCents: totalCents,
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: AppPrimaryButton(
            label: widget.isSellMode
                ? 'Revisar ordem de venda'
                : 'Revisar ordem de compra',
            onPressed: nextStep,
          ),
        ),
      ],
    );
  }

  // ── Step 1: Confirmação ───────────────────────────────────────────────────
  Widget _buildStep1(Color accentColor) {
    return BuyStepConfirm(
      startupName: widget.startupName,
      isSellMode: widget.isSellMode,
      tokenAmount: tokenAmount,
      pricePerTokenCents: widget.pricePerTokenCents,
      sellPriceCents: _sellPriceCents,
      totalCents: totalCents,
      walletBalance: walletBalance,
      accentColor: accentColor,
      onConfirm: confirmPurchase,
      isLoading: isLoading,
    );
  }

  // ── Step 2: Sucesso ───────────────────────────────────────────────────────
  Widget _buildStep2(Color accentColor) {
    return BuyStepSuccess(
      isSellMode: widget.isSellMode,
      onConcluir: nextStep,
    );
  }
}
