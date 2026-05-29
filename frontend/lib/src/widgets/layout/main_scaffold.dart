// Autor: Gustavo Alves de Siqueira Costa
// Data: 12/05/2026
// Descrição: Shell de navegação principal — define a BottomNavigationBar uma única vez
// e usa IndexedStack para preservar o estado de cada aba ao trocar de página.

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/pages/private/home/home_page.dart';
import 'package:mescla_invest/src/pages/private/balcao/balcao_page.dart';
import 'package:mescla_invest/src/pages/private/catalog/catalog_page.dart';
import 'package:mescla_invest/src/pages/private/wallet/wallet_page.dart';
import 'package:mescla_invest/src/pages/private/profile/profile_page.dart';

class MainScaffold extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final int initialIndex;

  const MainScaffold({super.key, this.usuario, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // isActive sinaliza para cada página quando ela está visível.
          // Como o IndexedStack mantém todas montadas, sem isso as páginas
          // nunca recarregariam ao trocar de aba.
          HomePage(usuario: widget.usuario, onTabSwitch: _switchTab, isActive: _currentIndex == 0),
          BalcaoNegociacaoPage(usuario: widget.usuario, onTabSwitch: _switchTab, isActive: _currentIndex == 1),
          InitialCatalogPage(usuario: widget.usuario, onTabSwitch: _switchTab, isActive: _currentIndex == 2),
          WalletPage(usuario: widget.usuario, onTabSwitch: _switchTab, isActive: _currentIndex == 3),
          ProfilePage(usuario: widget.usuario, onTabSwitch: _switchTab, isActive: _currentIndex == 4),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.5,
                color: _currentIndex == i ? AppColors.azul : AppColors.cinza200,
              ),
            )),
          ),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.branco,
            elevation: 0,
            currentIndex: _currentIndex,
            selectedItemColor: AppColors.azul,
            unselectedItemColor: AppColors.cinza500,
            onTap: _switchTab,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Início"),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mercado"),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Carteira"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
            ],
          ),
        ],
      ),
    );
  }
}
