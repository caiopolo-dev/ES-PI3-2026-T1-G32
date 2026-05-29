// Autor: Caio Ferreira Polo
// Descrição: Handler para cancelamento de oferta de venda de tokens no balcão

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";
import {cancelOffer as cancelOfferInRepo}
  from "../repositories/cancelOfferRepository";


export const cancelOffer = onCall(async (request)=> {
  requireAuth(request.auth);
  const {offerId} = request.data ?? {};

  if (!offerId || typeof offerId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "ID da oferta não informado"
    );
  }
  const result = await cancelOfferInRepo({
    offerId,
    sellerId: request.auth.uid,
  });

  return {
    success: true,
    data: result,
  };
});
