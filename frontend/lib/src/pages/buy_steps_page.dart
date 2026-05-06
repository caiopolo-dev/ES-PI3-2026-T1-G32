// Caio Ferreira Polo - 2RA 5002823

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BuyStepsPage extends StatefulWidget {
  @override
  State<BuyStepsPage> createState() => _BuyStepsPageState();

  final String startupName;

  const BuyStepsPage({
    super.key,
    required this.startupName,
  });
}

class _BuyStepsPageState extends State<BuyStepsPage> {
  int currentStep = 0;
  bool isLoading = false;
  String errorText = '';

  int tokenAmount = 1;

  static const List<String> _stepTitles = [
    'Quantidade de compra',
    'Confirmação de valor',
    'Agradecimento',
  ];

  bool validateStep() {
  setState(() => errorText = '');

  switch (currentStep) {
    case 0:
      if (tokenAmount <= 0) {
        setState(() => errorText = 'Selecione pelo menos 1 token para continuar.');
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
        return const Text('Aqui o usuário escolhe a quantidade');

        case 1:
        return const Text('Aqui o usuário confirma o valor');

        case 2:
        return const Text('Compra realizada com sucesso');

        default:
        return const SizedBox.shrink();
    }
  }

  void nextStep() {
    if(!validateStep()){
        return;
    }

    if (currentStep < 2){
        setState(() => currentStep++);
    }else{
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  child: Text(widget.startupName),
                ),
              ),
              Text(
                _stepTitles[currentStep],
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              buildStepContent(), 

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: nextStep,
                child: const Text('Próximo'),
              ),

              const SizedBox(height: 10,)

            
            ],
            ),
        
          )
        )
    );
    
  }
}