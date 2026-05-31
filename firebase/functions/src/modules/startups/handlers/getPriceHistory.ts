// Autor: Gustavo Alves de Siqueira Costa
// Data: 21/05/2026
// Descrição: Histórico de preços de uma startup para gráficos

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {startupRepository} from "../repositories/startupRepository";

export const getPriceHistory = onCall(async (request) => {
  // Requer autenticação para acessar histórico de preços.
  requireAuth(request.auth);

  // Valida e normaliza parâmetros de entrada.
  const startupId = request.data?.startupId as string | undefined;
  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório");
  }

  // Limita a quantidade de pontos retornados para evitar respostas muito
  // grandes; default 50 e máximo 200.
  const limit = Math.min(Number(request.data?.limit ?? 50), 200);

  // Recupera histórico ordenado pelo repositório.
  const data = await startupRepository.findPriceHistory(startupId, limit);

  return {data};
});
