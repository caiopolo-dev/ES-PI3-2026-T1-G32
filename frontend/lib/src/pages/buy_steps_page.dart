// Caio Ferreira Polo - 2RA 5002823

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class BuyStepsPage extends StatefulWidget{
    const BuyStepsPage({super.key});
    @override
    State<BuyStepsPage> createState() => _BuyStepsPageState();
}

class _BuyStepsPageState extends State<BuyStepsPage>{
    int currentStep = 0
    bool isLoading = false;
    String errorText = '';

    final tokenAmount = TextEditingController();



    static const List<String> _stepTitles = [
        'Quantidade de compra',
        'Confirmação de valor',
        'Agradecimento',
    ];

    

}