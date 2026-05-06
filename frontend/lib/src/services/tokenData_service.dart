import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
}




