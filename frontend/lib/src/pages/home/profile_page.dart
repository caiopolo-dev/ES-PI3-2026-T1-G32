// Autor: Gustavo Alves de Siqueira Costa
// Data: 04/05/2026
// Descrição: Tela de perfil do usuário, com informações da conta e opção de logout

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/src/pages/initial_page.dart';
import 'package:mescla_invest/src/pages/security/two_factor_setup_page.dart';
import 'package:mescla_invest/src/pages/home/home_page.dart';
import 'package:mescla_invest/src/pages/home/balcao_page.dart';
import 'package:mescla_invest/src/pages/home/catalog_page.dart';
import 'package:mescla_invest/src/pages/home/wallet_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? usuario;

  const ProfilePage({super.key, this.usuario});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    // Verifica se o usuário já tem TOTP registrado para exibir o toggle correto.
    _loadTwoFactorStatus();
  }

  // Consulta diretamente o Firebase Auth (client-side) para verificar se há
  // fatores registrados. Mais rápido do que chamar uma Cloud Function pois
  // a lista de fatores já está no token local após o login.
  Future<void> _loadTwoFactorStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      // getEnrolledFactors retorna a lista de fatores (TOTP, SMS etc.) da conta.
      final factors = await user.multiFactor.getEnrolledFactors();
      // Qualquer fator registrado considera o 2FA como ativo.
      if (mounted) setState(() => _twoFactorEnabled = factors.isNotEmpty);
    } catch (_) {}
  }

  // Faz logout e retorna para a tela inicial, limpando toda a pilha de navegação.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario ?? {};
    final nome = (usuario['nome'] ?? usuario['name']) as String? ?? '—';
    final email = usuario['email'] as String? ?? '—';
    final telefone = usuario['telefone'] as String? ?? '—';

    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.branco,
          border: Border(top: BorderSide(color: AppColors.cinza300)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.branco,
          elevation: 0,
          currentIndex: 4,
          selectedItemColor: AppColors.azul,
          unselectedItemColor: AppColors.cinza500,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomePage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BalcaoNegociacaoPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => InitialCatalogPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => WalletPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 4) return;
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Início"),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mercado"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Carteira"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 24),

                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.azul.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 52, color: AppColors.azul),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JosefinSans',
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Informações da conta',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.cinza500,
                        fontFamily: 'JosefinSans',
                      ),
                    ),

                    const SizedBox(height: 8),

                    _InfoTile(icon: Icons.email_outlined, label: 'Email', value: email),
                    _InfoTile(icon: Icons.phone_outlined, label: 'Telefone', value: telefone),

                    const SizedBox(height: 32),

                    const Text(
                      'Segurança',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.cinza500,
                        fontFamily: 'JosefinSans',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cinza100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline, color: AppColors.azul),
                        title: const Text(
                          'Autenticação de dois fatores',
                          style: TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                        ),
                        subtitle: Text(
                          _twoFactorEnabled ? 'Ativo' : 'Inativo',
                          style: const TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 12,
                            color: AppColors.cinza500,
                          ),
                        ),
                        trailing: Switch(
                          value: _twoFactorEnabled,
                          activeThumbColor: AppColors.azul,
                          activeTrackColor: AppColors.azul200,
                          inactiveTrackColor: AppColors.cinza200,
                          inactiveThumbColor: AppColors.cinza500,
                          onChanged: (value) async {
                            if (value) {
                              // Abre a tela de configuração do 2FA.
                              // TwoFactorSetupPage retorna `true` via Navigator.pop
                              // se o usuário completou o enrollment com sucesso.
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TwoFactorSetupPage(),
                               ),
                              );

                              // Atualiza o toggle somente se o 2FA foi ativado com sucesso.
                              if (result == true) {
                               setState(() => _twoFactorEnabled = true);
                             }
                           } else {
                             // Desativação de 2FA exige verificação de identidade adicional
                             // — redireciona para o suporte para evitar desativação acidental.
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                               content: Text('Para desativar, contate o suporte'),
                              ),
                             );
                           }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: AppColors.vermelho),
                        label: const Text(
                          'Sair da conta',
                          style: TextStyle(
                            color: AppColors.vermelho,
                            fontFamily: 'JosefinSans',
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.vermelho),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cinza100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.azul, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.cinza500,
                  fontFamily: 'JosefinSans',
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'JosefinSans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
