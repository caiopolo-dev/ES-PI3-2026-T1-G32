// Autor: Gustavo Alves de Siqueira Costa
// Data: 15/05/2026
// Descrição: Handler para listar as ofertas de venda do próprio usuário

import {onCall} from "firebase-functions/v2/https";
import {listOffersBySeller} from "../repositories/offersRepository";
import {requireAuth} from "../../../shared/validation";

export const listMyOffers = onCall(async (request) => {
  requireAuth(request.auth);

  const offers = await listOffersBySeller(request.auth.uid);

  return {data: offers};
});
