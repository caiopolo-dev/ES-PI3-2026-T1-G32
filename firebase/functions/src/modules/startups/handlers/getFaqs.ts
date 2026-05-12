// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Handler para buscar FAQs de uma startup

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {faqsRepository} from "../repositories/faqsRepository";
import {requireAuth} from "../../../shared/validation";

export const getFaqs = onCall(async (request) => {
  requireAuth(request.auth);

  const {startupId} = request.data;

  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório");
  }

  // Email do token é usado no repository para filtrar FAQs privadas:
  // o usuário só vê as próprias perguntas privadas.
  const email = request.auth.token.email ?? "";

  const faqs = await faqsRepository.findByStartup(startupId, email);

  return {success: true, data: faqs};
});
