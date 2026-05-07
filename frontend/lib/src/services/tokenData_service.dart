// Caio Ferreira Polo = 25002823

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TokenDataService {
  static void testeUsuarioLogado() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('Sem usuário logado');
      return;
    }

    print('Usuário logado: ${user.uid}');
  }

  static Future<int> getWalletBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Sem usuário logado');
      return 0 ;
    }

    final walletDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .collection('wallet')
    .doc('saldo')
    .get();

    final data = walletDoc.data();
    final saldo = data?['saldo'] ?? 0;
    return (saldo as num).toInt();
  }


  static Future<Map<String, dynamic>> buyOffer({
    required String offerId,
    required int quantity,
}) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('buyOffer');

    final result = await callable.call({
      'offerId': offerId,
      'quantity': quantity,
    });

    return {
      'success': true,
      'data': result.data['data'],
    };
  } on FirebaseFunctionsException catch (e) {
    return {
      'success': false,
      'message': e.message ?? 'Erro ao confirmar compra',
      'error': e.code,
    };
  } catch (e) {
    return {
      'success': false,
      'message': e.toString(),
      'error': 'unexpected',
    };
  }
}
}




