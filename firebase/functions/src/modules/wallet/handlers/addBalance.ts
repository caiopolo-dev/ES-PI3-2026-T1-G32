// Autor: Gustavo Alves de Siqueira Costa
// Data: 14/05/2026
// Descrição: Handler para adicionar saldo à carteira do usuário

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {addBalanceToWallet} from "../repositories/walletRepository";
import {requireAuth} from "../../../shared/validation";

export const addBalance = onCall(async (request) => {
  requireAuth(request.auth);

  const amountCents = Number(request.data?.amountCents);

  if (!Number.isInteger(amountCents) || amountCents <= 0) {
    throw new HttpsError("invalid-argument", "Valor inválido");
  }

  // Limite de R$ 50.000 por depósito
  if (amountCents > 5_000_000) {
    throw new HttpsError(
      "invalid-argument",
      "Valor máximo por depósito é R$ 50.000"
    );
  }

  await addBalanceToWallet(request.auth.uid, amountCents);
  return {success: true};
});
