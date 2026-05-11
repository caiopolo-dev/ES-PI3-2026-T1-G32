// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Retorna histórico de transações do usuário

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getTransactionHistoryByUserId} from "../repositories/walletRepository";

export const getTransactionHistory = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  try {
    return await getTransactionHistoryByUserId(request.auth.uid);
  } catch (e) {
    console.error("getTransactionHistory error:", e);
    throw new HttpsError("internal", "Erro ao buscar histórico");
  }
});
