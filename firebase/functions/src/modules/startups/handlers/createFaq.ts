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
  requireAuth(request.auth);

  const {startupId, pergunta, privada} = request.data;

  if (!startupId || !pergunta) {
    throw new HttpsError(
      "invalid-argument",
      "startupId e pergunta são obrigatórios"
    );
  }

  const uid = request.auth.uid;
  const email = request.auth.token.email ?? "";

  if (privada === true) {
    const hasTokens = await hasTokensForStartup(uid, startupId);
    if (!hasTokens) {
      throw new HttpsError(
        "permission-denied",
        "Apenas investidores podem enviar perguntas privadas"
      );
    }
  }

  // Nome vem do Firestore (campo 'name') pois o token Auth não o contém.
  const userDoc = await getUserById(uid);
  const nomeUsuario = (userDoc.data()?.name as string) ?? "";

  await faqsRepository.create(
    startupId, pergunta, privada === true, email, nomeUsuario
  );

  return {success: true};
});
