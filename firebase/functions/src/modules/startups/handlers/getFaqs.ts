// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Handler para buscar FAQs de uma startup

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {faqsRepository} from "../repositories/faqsRepository";
import {requireAuth} from "../../../shared/validation";
import {db} from "../../../shared/firebase";
import {USERS, USER_TOKENS} from "../../../shared/collections";

export const getFaqs = onCall(async (request) => {
  requireAuth(request.auth);

  const {startupId} = request.data;

  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório");
  }

  const uid = request.auth.uid;
  const email = request.auth.token.email!;

  const tokenDoc = await db
    .collection(USERS).doc(uid)
    .collection(USER_TOKENS).doc(startupId)
    .get();

  const hasTokens =
    tokenDoc.exists && Number(tokenDoc.data()?.quantidade ?? 0) > 0;

  const faqs = await faqsRepository.findByStartup(startupId, hasTokens, email);

  return {success: true, data: faqs};
});
