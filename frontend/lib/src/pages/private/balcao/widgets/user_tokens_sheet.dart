// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Bottom sheet de seleção de tokens do usuário no balcão

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/wallet_token_card.dart';

class UserTokensSheet extends StatefulWidget {
  const UserTokensSheet({super.key});

  @override
  State<UserTokensSheet> createState() => _UserTokensSheetState();
}

class _UserTokensSheetState extends State<UserTokensSheet> {
  static final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Map<String, dynamic>> _tokens = [];
  bool _isLoading = true;
  Map<String, String?> _logoUrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await WalletService.getUserTokens();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _tokens = List<Map<String, dynamic>>.from(result['tokens'] ?? []);
      }
    });
    _loadLogoUrls();
  }

  Future<void> _loadLogoUrls() async {
    final entries = await Future.wait(
      _tokens.map((t) async {
        final nome = (t['startupNome'] as String?) ?? '';
        final url = await StorageService.getStartupAsset(
          nome,
          'logoPhoto.jpeg',
        );
        return MapEntry(nome, url);
      }),
    );
    if (!mounted) return;
    setState(() => _logoUrls = Map.fromEntries(entries));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cinza300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Meus tokens',
                style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AppLoadingIndicator()
                : _tokens.isEmpty
                ? const Center(
                    child: Text(
                      'Você não possui tokens',
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        color: AppColors.cinza500,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _tokens.length,
                    itemBuilder: (context, index) {
                      final token = _tokens[index];
                      final logoUrl =
                          _logoUrls[token['startupNome'] as String? ?? ''];
                      return WalletTokenCard(
                        token: token,
                        logoUrl: logoUrl,
                        saldoVisivel: true,
                        onTap: () => Navigator.pop(context, token),
                        currencyFormat: _fmt,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
