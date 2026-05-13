// Autor: Rafael Mendes Valente
// Descrição: Handler para buscar saldo e tokens do usuário

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {exchangeRepository} from "../repositories/exchangeRepository";

export const getWalletInfo = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  const uid = request.auth.uid;

  const saldo = await exchangeRepository.getSaldo(uid);
  const tokens = await exchangeRepository.listarTokensDoUsuario(uid);

  return {
    success: true,
    data: {saldo, tokens},
  };
});
