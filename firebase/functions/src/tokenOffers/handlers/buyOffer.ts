// Caio Ferreira Polo - 25002823

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {buyTokenOffer} from "../repositories/offersRepository";

export const buyOffer = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuário não autenticado"
    );
  }

  const {offerId, quantity} = request.data ?? {};

  if (!offerId || typeof offerId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "ID da oferta não informado"
    );
  }

  const quantityNumber = Number(quantity);

  if (!Number.isInteger(quantityNumber) || quantityNumber <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade inválida"
    );
  }

  const result = await buyTokenOffer({
    offerId,
    buyerId: request.auth.uid,
    quantity: quantityNumber,
  });

  return {
    success: true,
    data: result,
  };
});
