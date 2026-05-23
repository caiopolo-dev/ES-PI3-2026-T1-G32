// Autor: Caio Ferreira Polo
// Descrição: Tela de compra de tokens em etapas (seleção de quantidade, revisão e confirmação)
import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/token_data_service.dart';
import '../../services/wallet_service.dart';

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

  Future<void> loadWalletBalance() async {
    final balance = await TokenDataService.getWalletBalance();
    if (!mounted) return;
    setState(() => walletBalance = balance);
  }

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

  String formatMoney(int cents) {
    final value = (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $value';
  }

  @override
  void initState() {
    super.initState();
    _sellPriceCents =
        widget.pricePerTokenCents > 0 ? widget.pricePerTokenCents : 100;
    _priceController = TextEditingController(
      text: _CurrencyFormatter.formatCents(_sellPriceCents),
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
            _priceController.text = _CurrencyFormatter.formatCents(1);
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
              // Indicador de etapas
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          left: i > 0 ? 4 : 0,
                          right: i < 2 ? 4 : 0,
                        ),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= currentStep
                              ? accentColor
                              : AppColors.cinza200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
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
        // Card de informação: saldo / tokens + preço
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cinza200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isSellMode ? 'Seus tokens' : 'Saldo em conta',
                      style: const TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 12,
                        color: AppColors.cinza500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isSellMode
                          ? '${widget.availableQuantity} tokens'
                          : formatMoney(walletBalance),
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.cinza200),
              const SizedBox(width: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      widget.isSellMode
                          ? '${widget.availableQuantity} disponíveis'
                          : '${formatMoney(widget.pricePerTokenCents)}/token',
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
        ),

        // Campo de preço editável (somente modo venda)
        if (widget.isSellMode) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cinza200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preço por token',
                  style: TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 14,
                    color: AppColors.cinza700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _priceController,
                      focusNode: _priceFocus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_CurrencyFormatter()],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        final digits =
                            value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.isEmpty) {
                          setState(() => _sellPriceCents = 0);
                          return;
                        }
                        final cents = int.tryParse(digits) ?? 0;
                        setState(
                            () => _sellPriceCents = cents.clamp(0, 5000000));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Seletor de quantidade
        const Text(
          'Quantidade de tokens',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: SizedBox(
                width: 60,
                child: TextField(
                  controller: _quantityController,
                  focusNode: _quantityFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
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
                        _quantityController.selection =
                            TextSelection.collapsed(
                                offset: _quantityController.text.length);
                      });
                    } else {
                      setState(() => tokenAmount = parsed);
                    }
                  },
                ),
              ),
            ),
            const Spacer(),
            _StepButton(label: '−', onPressed: tokenSub),
            const SizedBox(width: 10),
            _StepButton(label: '+', onPressed: tokenSum),
          ],
        ),

        const SizedBox(height: 20),

        // Total
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isSellMode ? 'Você receberá:' : 'Você pagará:',
                style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              Text(
                formatMoney(totalCents),
                style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: AppColors.branco,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              widget.isSellMode
                  ? 'Revisar ordem de venda'
                  : 'Revisar ordem de compra',
              style: const TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Confirmação ───────────────────────────────────────────────────
  Widget _buildStep1(Color accentColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cinza200),
          ),
          child: Column(
            children: [
              _ConfirmRow(label: 'Startup', value: widget.startupName),
              _Divider(),
              _ConfirmRowTokens(quantity: tokenAmount),
              _Divider(),
              _ConfirmRow(
                label: 'Preço por token',
                value: formatMoney(widget.isSellMode
                    ? _sellPriceCents
                    : widget.pricePerTokenCents),
              ),
              _Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isSellMode ? 'Você receberá' : 'Você pagará',
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    formatMoney(totalCents),
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              if (!widget.isSellMode) ...[
                _Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saldo após compra',
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 13,
                        color: AppColors.cinza500,
                      ),
                    ),
                    Text(
                      formatMoney(
                          (walletBalance - totalCents).clamp(0, walletBalance)),
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: walletBalance - totalCents >= 0
                            ? AppColors.azul
                            : AppColors.vermelho,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : confirmPurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: AppColors.branco,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.branco),
                  )
                : Text(
                    widget.isSellMode
                        ? 'Confirmar ordem de venda'
                        : 'Confirmar compra',
                    style: const TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Sucesso ───────────────────────────────────────────────────────
  Widget _buildStep2(Color accentColor) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.azulNoite, width: 3),
          ),
          child: const Icon(Icons.currency_exchange,
              size: 70, color: AppColors.preto),
        ),
        const SizedBox(height: 24),
        Text(
          widget.isSellMode ? 'Ordem de venda criada!' : 'Compra realizada!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Seu futuro se transforma e a\ninovação acelera.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 15,
            color: AppColors.cinza500,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: AppColors.branco,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text(
              'Concluir',
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _StepButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          fixedSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.preto,
          side: const BorderSide(color: AppColors.cinza300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.cinza200,
          margin: const EdgeInsets.symmetric(vertical: 12));
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 13,
                  color: AppColors.cinza500)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      );
}

class _ConfirmRowTokens extends StatelessWidget {
  final int quantity;
  const _ConfirmRowTokens({required this.quantity});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tokens',
              style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 13,
                  color: AppColors.cinza500)),
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
                  '$quantity tokens',
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
      );
}

// ─── Formatador de moeda ─────────────────────────────────────────────────────

class _CurrencyFormatter extends TextInputFormatter {
  static const int _maxCents = 5000000;

  static String formatCents(int cents) {
    final c = cents.clamp(0, _maxCents);
    final reais = c ~/ 100;
    final centavos = (c % 100).toString().padLeft(2, '0');
    final reaisStr = reais.toString();
    final buf = StringBuffer();
    for (int i = 0; i < reaisStr.length; i++) {
      if (i > 0 && (reaisStr.length - i) % 3 == 0) buf.write('.');
      buf.write(reaisStr[i]);
    }
    return '${buf.toString()},$centavos';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
          text: '', selection: const TextSelection.collapsed(offset: 0));
    }
    int cents = int.tryParse(digits) ?? 0;
    if (cents > _maxCents) cents = _maxCents;
    final formatted = formatCents(cents);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
