// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Handler para buscar FAQs de uma startup

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {faqsRepository} from "../repositories/faqsRepository";
import {hasTokensForStartup} from "../../users/repositories/userRepository";
import {requireAuth} from "../../../shared/validation";

export const getFaqs = onCall(async (request) => {
  // Requer autenticação do usuário.
  requireAuth(request.auth);

  // Validação simples do payload.
  const {startupId} = request.data;

  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório");
  }

  // Usamos o UID e email do token para aplicar regras de visibilidade.
  const uid = request.auth.uid;
  const email = request.auth.token.email ?? "";

  // Determina se o usuário possui tokens da startup — isso controla se
  // FAQs privadas devem ser incluídas na resposta.
  const hasTokens = await hasTokensForStartup(uid, startupId);

  // O repositório retorna FAQs já filtradas conforme `hasTokens` e o email
  // do autor (por exemplo, para incluir perguntas privadas do próprio autor).
  const faqs = await faqsRepository.findByStartup(startupId, hasTokens, email);

  return {success: true, data: faqs};
});
