// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Handler para criar uma FAQ em uma startup

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {faqsRepository} from "../repositories/faqsRepository";
import {getUserById} from "../../users/repositories/userRepository";

export const createFaq = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  const {startupId, pergunta, privada} = request.data;

  if (!startupId || !pergunta) {
    throw new HttpsError(
      "invalid-argument",
      "startupId e pergunta são obrigatórios"
    );
  }

  const uid = request.auth.uid;
  // Email e nome são lidos do token/Firestore e nunca do request.data
  // para evitar que o cliente envie valores falsos.
  const email = request.auth.token.email ?? "";

  // Nome de exibição vem do Firestore (campo 'name') pois o token Auth não o contém.
  const userDoc = await getUserById(uid);
  const nomeUsuario = (userDoc.data()?.name as string) ?? "";

  await faqsRepository.create(
    startupId, pergunta, privada === true, email, nomeUsuario
  );

  return {success: true};
});
