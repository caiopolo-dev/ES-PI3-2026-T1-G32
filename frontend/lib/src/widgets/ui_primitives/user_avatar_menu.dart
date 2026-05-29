// Autor: Gustavo Alves de Siqueira Costa
// Data: 12/05/2026
// Descrição: Avatar do usuário com menu de contexto — reutilizado em todas as AppBars

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/pages/public/initial_page.dart';

class UserAvatarMenu extends StatelessWidget {
  final Map<String, dynamic>? usuario;
  final VoidCallback? onPerfilTap;

  const UserAvatarMenu({super.key, this.usuario, this.onPerfilTap});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_visible', false);
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = ((usuario?['nome'] ?? usuario?['name']) as String?) ?? '';
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'perfil') {
            onPerfilTap?.call();
          } else if (value == 'sair') {
            _logout(context);
          }
        },
        color: AppColors.branco,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.cinza200),
        ),
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'perfil',
            child: Row(children: [
              Icon(Icons.person_outline, size: 20, color: AppColors.preto87),
              SizedBox(width: 12),
              Text('Meu Perfil'),
            ]),
          ),
          PopupMenuItem<String>(
            enabled: false,
            height: 8,
            padding: EdgeInsets.zero,
            child: Divider(indent: 16, endIndent: 16, thickness: 1, height: 1, color: AppColors.cinza200),
          ),
          const PopupMenuItem(
            value: 'sair',
            child: Row(children: [
              Icon(Icons.logout, size: 20, color: AppColors.vermelho),
              SizedBox(width: 12),
              Text('Sair', style: TextStyle(color: AppColors.vermelho)),
            ]),
          ),
        ],
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.azul,
          child: Text(
            inicial,
            style: const TextStyle(
              inherit: false,
              color: AppColors.branco,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
