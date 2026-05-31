// Caio ferreira Polo - RA 25002823

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {buyStartupTokenDirectly} from
  "../repositories/startupPurchaseRepository";

export const buyStartupToken = onCall(async (request)=>{
  // Requer usuário autenticado.
  requireAuth(request.auth);

  // Valida inputs do payload. `startupId` deve ser string e `quantity`
  // deve ser inteiro positivo.
  const {startupId, quantity} = request.data?? {};
  if (!startupId || typeof startupId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "ID da startup não informado"
    );
  }

  const quantityNumber = Number(quantity);

  if (!Number.isInteger(quantityNumber) || quantityNumber <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade inválida"
    );
  }

  // Encaminha para o repositório que realiza a compra direta de tokens.
  // O repositório deve tratar lógica de saldo, tokens disponíveis e atomicidade.
  const result = await buyStartupTokenDirectly({
    startupId,
    buyerId: request.auth.uid,
    quantity: quantityNumber,
  });

  return {
    success: true,
    data: result,
  };
});
