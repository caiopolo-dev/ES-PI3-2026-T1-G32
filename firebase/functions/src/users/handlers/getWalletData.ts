// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Retorna saldo e resumo da carteira do usuário

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getWalletDataByUserId} from "../repositories/walletRepository";

export const getWalletData = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  try {
    return await getWalletDataByUserId(request.auth.uid);
  } catch (e) {
    throw new HttpsError("internal", "Erro ao buscar carteira");
  }
});