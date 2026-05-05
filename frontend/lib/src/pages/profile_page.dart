// Autor: Gustavo Alves de Siqueira Costa
// Data: 04/05/2026
// Descrição: Tela de perfil do usuário, com informações da conta e opção de logout

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/initial_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? usuario;

  const ProfilePage({super.key, this.usuario});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _twoFactorEnabled = false;

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 52, color: Colors.blue),
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
                        color: Colors.black45,
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
                        color: Colors.black45,
                        fontFamily: 'JosefinSans',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline, color: Colors.blue),
                        title: const Text(
                          'Autenticação de dois fatores',
                          style: TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                        ),
                        subtitle: const Text(
                          'Em breve',
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 12,
                            color: Colors.black38,
                          ),
                        ),
                        trailing: Switch(
                          value: _twoFactorEnabled,
                          activeColor: Colors.blue,
                          onChanged: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Autenticação de dois fatores em breve'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Sair da conta',
                          style: TextStyle(
                            color: Colors.red,
                            fontFamily: 'JosefinSans',
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
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
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
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
