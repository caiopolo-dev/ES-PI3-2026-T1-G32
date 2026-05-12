// Autor: Caio Ferreira Polo
// Descrição: Handler para retornar o saldo e resumo da carteira do usuário
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getWalletDataByUserId} from "../repositories/walletRepository";
import {requireAuth} from "../../../shared/validation";

export const getWalletInfo = onCall(async (request) => {
  requireAuth(request.auth);

  try {
    return await getWalletDataByUserId(request.auth.uid);
  } catch (e) {
    throw new HttpsError("internal", "Erro ao buscar carteira");
  }
});
