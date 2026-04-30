// Caio Ferreira polo - 25002823
//Pagina do balcão de negociação

import 'package:flutter/material.dart';

class BalcaoNegociacaoPage extends StatefulWidget {
  const BalcaoNegociacaoPage({super.key});

  @override
  State<BalcaoNegociacaoPage> createState() => _BalcaoNegociacaoPageState();
}

class _BalcaoNegociacaoPageState extends State<BalcaoNegociacaoPage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // 0 = Mercado, 1 = Catálogo, 2 = Carteira
        selectedItemColor: const Color.fromARGB(255, 122, 137, 150),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mercado"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Carteira"),
        ],
      ),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),    
          child: Column(
            children: [
              const SizedBox(height: 20),

              TextField(
                decoration: InputDecoration(
                  hintText: "Buscar startup",
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color.fromARGB(189, 186, 186, 59),
                      width: 1.0
                    ),
                    borderRadius: BorderRadius.circular(20),
                  )
                  
                ),
              )
            ]
          ),
        ),
      ),
    );
  }
}


  
 