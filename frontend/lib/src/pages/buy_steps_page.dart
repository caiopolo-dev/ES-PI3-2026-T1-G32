// Caio Ferreira Polo - RA 25002823
import 'package:flutter/material.dart';
import '../services/tokenData_service.dart';

class BuyStepsPage extends StatefulWidget {
  @override
  State<BuyStepsPage> createState() => _BuyStepsPageState();

  final String startupName;
  final int availableQuantity;
  final int pricePerTokenCents;
  final String offerId;

  const BuyStepsPage({
    super.key,
    required this.startupName,
    required this.availableQuantity,
    required this.pricePerTokenCents,
    required this.offerId,
  });
}

class _BuyStepsPageState extends State<BuyStepsPage> {
  int currentStep = 0;
  bool isLoading = false;
  String errorText = '';

  int tokenAmount = 1;
  int walletBalance = 0;

  static const List<String> _stepTitles = [
    'Compra de token',
    'Confirmação de valor',
    'Agradecimento',
  ];

  Future<void> loadWalletBalance() async {
    final balance = await TokenDataService.getWalletBalance();

    if (!mounted) return;

    setState(() {
      walletBalance = balance;
    });
  }

  int get totalCents => tokenAmount * widget.pricePerTokenCents;

  void tokenSum() {
    if (tokenAmount < widget.availableQuantity) {
      setState(() {
        tokenAmount++;
      });
    }
  }

  void tokenSub() {
    if (tokenAmount > 1) {
      setState(() {
        tokenAmount--;
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
    loadWalletBalance();
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo em conta corrente:',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  formatMoney(walletBalance),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),

            const SizedBox(height: 4),

            const Divider(
              height: 18,
              thickness: 1,
              color: Colors.black38,
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor do token',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  formatMoney(widget.pricePerTokenCents),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),

            const SizedBox(height: 350),

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
                    Text(
                      tokenAmount.toString(),
                      style: const TextStyle(fontSize: 30),
                    ),

                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: tokenSub ,
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size(42, 42),
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                              color: Colors.black54,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
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

                        const SizedBox(width: 20),

                        OutlinedButton(
                          onPressed: tokenSum,
                          style: OutlinedButton.styleFrom(
                            fixedSize: const Size(42, 42),
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                              color: Colors.black54,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
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
                  color: Colors.black38,
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
                const SizedBox(height: 20),

                SizedBox(
                width: 300,
                height: 48,
                child: ElevatedButton(
                  onPressed: nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Revisar ordem de compra',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'JosefinSans',
                    ),
                  ),
                ),
              ),



              ],
            ),
          ],
        );

      case 1:
        return Column(
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
              color: Colors.black38,
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
                  formatMoney(widget.pricePerTokenCents),
                  style: const TextStyle(fontSize: 20),
                ),
                
              ],
            ),
            const SizedBox(height: 4),
            const Divider(
              height: 18,
              thickness: 1,
              color: Colors.black38,
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

            const SizedBox(height: 410),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const SizedBox(height: 10),

                const Divider(
                  height: 18,
                  thickness: 1,
                  color: Colors.black38,
                ),


                const SizedBox(height: 30),

                SizedBox(
                width: 300,
                height: 48,
                child: ElevatedButton(
                  onPressed: nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Confirmar ordem de compra',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'JosefinSans',
                    ),
                  ),
                ),
              ),



              ],
            ),
          ],
        );
        
        


      case 2:
        return const Text('Compra realizada com sucesso');

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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (currentStep == 0) {
              Navigator.pop(context);
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

              buildStepContent(),

            ],
          ),
        ),
      ),
    );
  }
}