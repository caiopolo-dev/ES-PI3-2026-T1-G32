// Caio ferreira Polo - RA 25002823

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {buyStartupTokenDirectly} from
  "../repositories/startupPurchaseRepository";

export const buyStartupToken = onCall(async (request)=>{
  requireAuth(request.auth);
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
