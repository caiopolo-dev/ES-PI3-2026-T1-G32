// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Handler para buscar FAQs de uma startup

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {faqsRepository} from "../repositories/faqsRepository";
import {hasTokensForStartup} from "../../users/repositories/userRepository";
import {requireAuth} from "../../../shared/validation";

export const getFaqs = onCall(async (request) => {
  requireAuth(request.auth);

  const {startupId} = request.data;

  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório");
  }

  const uid = request.auth.uid;
  const email = request.auth.token.email!;

  const hasTokens = await hasTokensForStartup(uid, startupId);

  const faqs = await faqsRepository.findByStartup(startupId, hasTokens, email);

  return {success: true, data: faqs};
});
