// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Service responsável pela resolução de URLs do Firebase Storage

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  // Resolve URLs do Firebase Storage para links HTTPS de download.
  // O VideoPlayerController e NetworkImage requerem HTTPS, não gs://.
  // Suporta tanto o formato gs:// quanto o formato https://storage.googleapis.com/.
  static Future<String> getDownloadUrl(String url) async {
    if (url.startsWith('gs://')) {
      return FirebaseStorage.instance.refFromURL(url).getDownloadURL();
    }
    if (url.startsWith('https://storage.googleapis.com/')) {
      // Converte de volta para gs:// para usar a API do SDK e obter token de acesso.
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final bucket = segments[0];
        final path = segments.sublist(1).join('/');
        return FirebaseStorage.instance
            .refFromURL('gs://$bucket/$path')
            .getDownloadURL();
      }
    }
    return url;
  }
}
