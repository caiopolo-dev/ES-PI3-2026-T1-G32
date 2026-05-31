// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Handler para criar uma FAQ em uma startup

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {faqsRepository} from "../repositories/faqsRepository";
import {
  getUserById,
  hasTokensForStartup,
} from "../../users/repositories/userRepository";
import {requireAuth} from "../../../shared/validation";

export const createFaq = onCall(async (request) => {
  // Requer autenticação; lança HttpsError se o usuário não estiver autenticado.
  requireAuth(request.auth);

  // Validação mínima do payload: startupId e pergunta são obrigatórios.
  const {startupId, pergunta, privada} = request.data;

  if (!startupId || !pergunta) {
    throw new HttpsError(
      "invalid-argument",
      "startupId e pergunta são obrigatórios"
    );
  }

  // Dados do usuário a partir do contexto de autenticação.
  const uid = request.auth.uid;
  const email = request.auth.token.email ?? "";

  // Permissão para perguntas privadas: apenas usuários com tokens da startup
  // podem enviar perguntas marcadas como `privada`.
  if (privada === true) {
    const hasTokens = await hasTokensForStartup(uid, startupId);
    if (!hasTokens) {
      throw new HttpsError(
        "permission-denied",
        "Apenas investidores podem enviar perguntas privadas"
      );
    }
  }

  // Obtém o nome do usuário no Firestore — o token Auth pode não conter
  // o campo `name`, por isso lemos do documento do usuário para registrar
  // a FAQ com o nome correto do autor.
  const userDoc = await getUserById(uid);
  const nomeUsuario = (userDoc.data()?.name as string) ?? "";

  // Persiste a FAQ; o repositório espera startupId, texto, flag privada,
  // email e nome do autor.
  await faqsRepository.create(
    startupId, pergunta, privada === true, email, nomeUsuario
  );

  return {success: true};
});
