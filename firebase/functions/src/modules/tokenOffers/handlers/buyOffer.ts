// Autor: Caio Ferreira Polo
// Descrição: Handler para compra de oferta de tokens no balcão

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {buyTokenOffer} from "../repositories/offersRepository";
import {requireAuth} from "../../../shared/validation";

export const buyOffer = onCall(async (request) => {
  requireAuth(request.auth);

  const {offerId, quantity} = request.data ?? {};

  if (!offerId || typeof offerId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "ID da oferta não informado"
    );
  }

  // Flutter envia quantity como num; Number() converte para JS number,
  // e isInteger() garante que não chegue valor fracionário.
  const quantityNumber = Number(quantity);

  if (!Number.isInteger(quantityNumber) || quantityNumber <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade inválida"
    );
  }

  // buyerId vem do token de auth para evitar que o cliente envie um ID falso.
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
