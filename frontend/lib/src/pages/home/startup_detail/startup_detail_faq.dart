// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Dialog e modelo de FAQ da tela de detalhes de startup

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/services/faq_service.dart';

class FaqResult {
  final String pergunta;
  final bool privada;
  const FaqResult(this.pergunta, this.privada);
}

class FaqDialog extends StatefulWidget {
  final String startupId;
  const FaqDialog({super.key, required this.startupId});

  @override
  State<FaqDialog> createState() => _FaqDialogState();
}

class _FaqDialogState extends State<FaqDialog> {
  final _controller = TextEditingController();
  bool _privada = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pergunta = _controller.text.trim();
    if (pergunta.isEmpty) return;
    setState(() => _sending = true);
    final result = await FaqService.createFaq(
      startupId: widget.startupId,
      pergunta: pergunta,
      privada: _privada,
    );
    if (!mounted) return;
    if (result['success'] as bool) {
      Navigator.pop(context, FaqResult(pergunta, _privada));
    } else {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] as String? ?? 'Erro ao enviar pergunta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Enviar pergunta'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              autocorrect: false,
              enableSuggestions: false,
              smartQuotesType: SmartQuotesType.disabled,
              decoration: InputDecoration(
                hintText: 'Digite sua pergunta...',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _privada,
                  activeThumbColor: Colors.blue,
                  activeTrackColor: Colors.blue.shade200,
                  inactiveTrackColor: Colors.grey.shade200,
                  inactiveThumbColor: Colors.grey,
                  onChanged: (v) => setState(() => _privada = v),
                ),
                Text(_privada ? 'Privada' : 'Pública',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black,
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
