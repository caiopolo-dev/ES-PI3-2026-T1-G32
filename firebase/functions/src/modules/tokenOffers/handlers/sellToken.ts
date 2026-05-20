// Autor: Rafael Mendes Valente
// Descrição: Handler para criação de oferta de venda de tokens no balcão

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {createSellOffer as createSellOfferInRepo}
  from "../repositories/sellTokenRepository";

export const createSellOffer = onCall(async (request) => {
  requireAuth(request.auth);

  const {startupId, quantity, pricePerTokenCents} = request.data ?? {};

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

  const priceNumber = Number(pricePerTokenCents);

  const priceInvalid = !Number.isInteger(priceNumber) ||
    priceNumber < 1 || priceNumber > 5000000;
  if (priceInvalid) {
    throw new HttpsError(
      "invalid-argument",
      "Preço inválido. Deve ser entre R$0,01 e R$50.000"
    );
  }

  const result = await createSellOfferInRepo({
    startupId,
    sellerId: request.auth.uid,
    quantity: quantityNumber,
    pricePerTokenCents: priceNumber,
  });

  return {
    success: true,
    data: result,
  };
});
