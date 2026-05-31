// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Retorna histórico de transações do usuário

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getTransactionHistoryByUserId} from "../repositories/walletRepository";
import {requireAuth} from "../../../shared/validation";

// Handler que retorna o histórico de transações do usuário.
// - Requer autenticação.
// - Encapsula erros do repositório e mapeia para `HttpsError` para o cliente.

export const getTransactionHistory = onCall(async (request) => {
  requireAuth(request.auth);

  try {
    return await getTransactionHistoryByUserId(request.auth.uid);
  } catch (e) {
    console.error("getTransactionHistory error:", e);
    throw new HttpsError("internal", "Erro ao buscar histórico");
  }
});
