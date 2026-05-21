// Autor: Gustavo Alves de Siqueira Costa
// Data: 21/05/2026
// Descrição: Histórico de preços de uma startup para gráficos

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {startupRepository} from "../repositories/startupRepository";

export const getPriceHistory = onCall(async (request) => {
  requireAuth(request.auth);

  const startupId = request.data?.startupId as string | undefined;
  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId é obrigatório");
  }

  const limit = Math.min(Number(request.data?.limit ?? 50), 200);

  const data = await startupRepository.findPriceHistory(startupId, limit);

  return {data};
});
