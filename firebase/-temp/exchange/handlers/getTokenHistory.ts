// Autor: Rafael Mendes Valente
// Descrição: Handler para buscar histórico de transações do usuário
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {exchangeRepository} from "../repositories/exchangeRepository";
export const getTokenHistory = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }
  const uid = request.auth.uid;
  const transacoes = await exchangeRepository.listarTransacoes(uid);
  return {
    success: true,
    data: transacoes,
  };
});
