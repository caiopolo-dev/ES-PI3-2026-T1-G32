// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Retorna lista de tokens adquiridos pelo usuário

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getUserTokensByUserId} from "../repositories/walletRepository";

export const getUserTokens = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  try {
    return await getUserTokensByUserId(request.auth.uid);
  } catch (e) {
    throw new HttpsError("internal", "Erro ao buscar tokens do usuário");
  }
});
