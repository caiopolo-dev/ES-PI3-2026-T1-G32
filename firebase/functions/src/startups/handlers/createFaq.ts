// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Handler para criar uma FAQ em uma startup

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";
import {faqsRepository} from "../repositories/faqsRepository";

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
  const email = request.auth.token.email ?? "";

  const userDoc = await getFirestore()
    .collection("users").doc(uid).get();
  const nomeUsuario = (userDoc.data()?.name as string) ?? "";

  await faqsRepository.create(
    startupId, pergunta, privada === true, email, nomeUsuario
  );

  return {success: true};
});
