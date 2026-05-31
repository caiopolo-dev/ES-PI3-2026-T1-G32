// Autor: Rafael Mendes Valente
// Descrição: Handler para criação de oferta de venda de tokens no balcão

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {createSellOffer as createSellOfferInRepo}
  from "../repositories/sellTokenRepository";

export const createSellOffer = onCall(async (request) => {
  // Requer autenticação para criar uma oferta.
  requireAuth(request.auth);

  // Valida argumentos básicos do payload.
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

  // `pricePerTokenCents` deve ser inteiro em centavos. Validamos faixa
  // mínima (R$0,01) e máxima (R$50.000 = 5_000_000 centavos) para proteger
  // contra valores abusivos.
  const priceNumber = Number(pricePerTokenCents);

  const priceInvalid = !Number.isInteger(priceNumber) ||
    priceNumber < 1 || priceNumber > 5000000;
  if (priceInvalid) {
    throw new HttpsError(
      "invalid-argument",
      "Preço inválido. Deve ser entre R$0,01 e R$50.000"
    );
  }

  // Delegamos ao repositório que deve: reservar tokens, criar a oferta e
  // garantir atomicidade das operações.
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

