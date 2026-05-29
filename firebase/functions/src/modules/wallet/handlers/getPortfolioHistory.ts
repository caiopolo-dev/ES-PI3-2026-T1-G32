// Autor: Caio Ferreira Polo - 25002823


import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {getPortfolioHistoryByUserId} from
  "../repositories/portfolioRepository";

export const getPortfolioHistory = onCall(async (request) => {
  requireAuth(request.auth);

  try {
    return await getPortfolioHistoryByUserId(request.auth.uid);
  } catch (e) {
    console.error("getPortfolioHistory error:", e);
    throw new HttpsError(
      "internal",
      "Erro ao buscar histórico do portfólio"
    );
  }
});
