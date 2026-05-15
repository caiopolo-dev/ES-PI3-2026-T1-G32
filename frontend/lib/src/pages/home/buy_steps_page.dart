// Autor: Caio Ferreira Polo
// Descrição: Tela de compra de tokens em etapas (seleção de quantidade, revisão e confirmação)
import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../../services/tokenData_service.dart';
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
  final TextEditingController _quantityController = TextEditingController(text: '1');
  late final TextEditingController _priceController;

  List<String> get _stepTitles => widget.isSellMode
      ? ['Venda de token', 'Confirmação de venda', 'Ordem criada']
      : ['Compra de token', 'Confirmação de valor', 'Agradecimento'];

  // Saldo armazenado em centavos para comparação direta com totalCents
  // sem precisar converter unidades no momento da validação.
  // Carrega no initState para que já esteja disponível quando o usuário tentar avançar.
  Future<void> loadWalletBalance() async {
    final balance = await TokenDataService.getWalletBalance();

    if (!mounted) return;

    setState(() {
      walletBalance = balance;
    });
  }

  int get totalCents => tokenAmount * (widget.isSellMode ? _sellPriceCents : widget.pricePerTokenCents);

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

  setState(() {
    isLoading = false;
  });

  if (result['success'] == true) {
    setState(() {
      currentStep = 2;
    });
  } else {
    setState(() {
      errorText = result['message'] ?? 'Erro ao confirmar compra';
    });
  }
}


  String formatMoney(int cents) {
    final value = (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $value';
  }

  @override
  void initState() {
    super.initState();
    _sellPriceCents = widget.pricePerTokenCents > 0 ? widget.pricePerTokenCents : 100;
    _priceController = TextEditingController(
      text: _CurrencyFormatter.formatCents(_sellPriceCents),
    );
    loadWalletBalance();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }




  bool validateStep() {
    setState(() => errorText = '');

    switch (currentStep) {
      case 0:
        if (tokenAmount <= 0) {
          setState(() => errorText = 'Selecione pelo menos 1 token para continuar.');
          return false;
        }
        if (tokenAmount > widget.availableQuantity) {
          setState(() => errorText = 'Quantidade maior que a disponível.');
          return false;
        }
        if (widget.isSellMode && (_sellPriceCents < 1 || _sellPriceCents > 5000000)) {
          setState(() => errorText = 'Preço inválido. Use entre R\$ 0,01 e R\$ 50.000,00.');
          return false;
        }
        if (!widget.isSellMode && totalCents > walletBalance) {
          setState(() => errorText = 'Saldo insuficiente para esta compra.');
          return false;
        }
        return true;

      case 1:
        return true;

      case 2:
        return true;

      default:
        return false;
    }
  }







  Widget buildStepContent() {
    switch (currentStep) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isSellMode ? 'Você receberá:' : 'Saldo em conta:',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  widget.isSellMode ? formatMoney(totalCents) : formatMoney(walletBalance),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Divider(
              height: 18,
              thickness: 1,
              color: AppColors.cinza500,
            ),

            const SizedBox(height: 4),

            widget.isSellMode
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Preço por token', style: TextStyle(fontSize: 20)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.azul.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.azul.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_CurrencyFormatter()],
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.azul,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  final cents = int.tryParse(digits) ?? 0;
                                  setState(() => _sellPriceCents = cents.clamp(1, 5000000));
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit, size: 14, color: AppColors.azul),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor do token', style: TextStyle(fontSize: 20)),
                      Text(formatMoney(widget.pricePerTokenCents), style: const TextStyle(fontSize: 20)),
                    ],
                  ),

            const Spacer(),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Quantidade',
                  style: TextStyle(fontSize: 20),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.azul.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.azul.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azul,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed == null || parsed < 1) {
                                  setState(() => tokenAmount = 1);
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      _quantityController.text = '1';
                                      _quantityController.selection =
                                          const TextSelection.collapsed(offset: 1);
                                    }
                                  });
                                } else if (parsed > widget.availableQuantity) {
                                  setState(() {
                                    tokenAmount = widget.availableQuantity;
                                    _quantityController.text = tokenAmount.toString();
                                    _quantityController.selection = TextSelection.collapsed(
                                      offset: _quantityController.text.length,
                                    );
                                  });
                                } else {
                                  setState(() => tokenAmount = parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit, size: 14, color: AppColors.azul),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: tokenSub,
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size(42, 42),
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.preto,
                            side: BorderSide(color: AppColors.cinza500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '-',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        OutlinedButton(
                          onPressed: tokenSum,
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size(42, 42),
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.preto,
                            side: BorderSide(color: AppColors.cinza500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Divider(
                  height: 18,
                  thickness: 1,
                  color: AppColors.cinza500,
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total estimado:',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      formatMoney(totalCents),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 6,
                    shadowColor: AppColors.azul.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppColors.azul800, width: 0.25),
                    ),
                  ),
                  child: Text(
                    widget.isSellMode ? 'Revisar ordem de venda' : 'Revisar ordem de compra',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'JosefinSans',
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ],
        );

      case 1:
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantidade',
                  style: TextStyle(fontSize: 20),
                  
                ),
                Text(
                  tokenAmount.toString(),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Divider(
              height: 18,
              thickness: 1,
              color: AppColors.cinza500,
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor unitário',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  formatMoney(widget.isSellMode ? _sellPriceCents : widget.pricePerTokenCents),
                  style: const TextStyle(fontSize: 20),
                ),
                
              ],
            ),
            const SizedBox(height: 4),
            const Divider(
              height: 18,
              thickness: 1,
              color: AppColors.cinza500,
            ),
            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                      'Total estimado:',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      formatMoney(totalCents),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ],
            ),

            if (!widget.isSellMode) ...[
              const SizedBox(height: 4),
              const Divider(height: 18, thickness: 1, color: AppColors.cinza500),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saldo após compra:', style: TextStyle(fontSize: 16, color: AppColors.cinza500)),
                  Text(
                    formatMoney((walletBalance - totalCents).clamp(0, walletBalance)),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: walletBalance - totalCents >= 0 ? AppColors.azul : AppColors.vermelho,
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            const Divider(
              height: 18,
              thickness: 1,
              color: AppColors.cinza500,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isLoading ? null : confirmPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azul,
                foregroundColor: AppColors.branco,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 6,
                shadowColor: AppColors.azul.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.azul800, width: 0.25),
                ),
              ),
              child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.branco,
                    ),
                  )
                : Text(
                    widget.isSellMode ? 'Confirmar ordem de venda' : 'Confirmar ordem de compra',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'JosefinSans',
                    ),
                  ),
            ),

            const SizedBox(height: 20),
              ],
            ),
          ],
        );
        
        


      case 2:
        return Column(
          children: [
            const SizedBox(height: 60),

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.azulNoite,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.currency_exchange,
                size: 70,
                color: AppColors.preto,
              ),
            ),

            const SizedBox(height: 55),

            Text(
              widget.isSellMode ? 'Ordem de venda criada!' : 'Ordem de compra emitida!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                fontFamily: 'JosefinSans',
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Seu futuro se transforma e a inovação\nacelera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'JosefinSans',
              ),
            ),


            
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void nextStep() {
    if (!validateStep()) {
      return;
    }

    if (currentStep < 2) {
      setState(() => currentStep++);
    } else {
      // Retorna true para o chamador saber que uma compra foi concluída
      // e que ele deve recarregar os dados (ofertas, carteira etc.).
      Navigator.pop(context, true);
    }
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
          onPressed: () {
            if (currentStep == 0) {
              // Sem compra: descarta sem sinalizar mudança.
              Navigator.pop(context);
            } else if (currentStep == 2) {
              // Compra já confirmada: sinaliza true para o chamador recarregar.
              Navigator.pop(context, true);
            } else {
              setState(() {
                currentStep--;
              });
            }
          },
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  child: Text(
                    widget.startupName,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _stepTitles[currentStep],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 30),

              Expanded(child: buildStepContent()),
              if (errorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    errorText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.vermelho),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyFormatter extends TextInputFormatter {
  static const int _maxCents = 5000000;

  static String formatCents(int cents) {
    final c = cents.clamp(1, _maxCents);
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
        text: '0,01',
        selection: const TextSelection.collapsed(offset: 4),
      );
    }
    int cents = int.tryParse(digits) ?? 0;
    if (cents > _maxCents) cents = _maxCents;
    if (cents < 1) cents = 1;
    final formatted = formatCents(cents);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}