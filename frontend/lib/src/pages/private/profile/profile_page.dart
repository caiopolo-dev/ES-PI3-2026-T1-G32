// Autor: Gustavo Alves de Siqueira Costa
// Data: 04/05/2026
// Descrição: Tela de perfil do usuário, com informações da conta e opção de logout

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/src/pages/public/initial_page.dart';
import 'package:mescla_invest/src/pages/private/profile/two_factor_setup_page.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final bool isActive;

  const ProfilePage({super.key, this.usuario, this.onTabSwitch, this.isActive = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _twoFactorEnabled = false;

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reavalia o status do 2FA ao abrir o perfil,
    // caso tenha sido ativado em outra sessão entre abas.
    if (widget.isActive && !oldWidget.isActive) _loadTwoFactorStatus();
  }

  @override
  void initState() {
    super.initState();
    // Verifica se o usuário já tem TOTP registrado para exibir o toggle correto.
    if (widget.isActive) _loadTwoFactorStatus();
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
    } catch (_) {
      if (mounted) setState(() => _twoFactorEnabled = false);
    }
  }

  // Faz logout e retorna para a tela inicial, limpando toda a pilha de navegação.
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_visible', false);
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
                              if (result == true && mounted) {
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
                      child: AppOutlineButton(
                        label: 'Sair da conta',
                        onPressed: _logout,
                        color: AppColors.vermelho,
                        borderRadius: 12,
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
