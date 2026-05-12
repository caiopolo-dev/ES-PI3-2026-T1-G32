// Autor: Caio Ferreira Polo
// Descrição: Handler para listar as ofertas de tokens disponíveis no balcão

import {onCall} from "firebase-functions/v2/https";
import {listAllOffers} from "../repositories/offersRepository";
import {requireAuth} from "../../../shared/validation";

export const listOffers = onCall(async (request)=>{
  requireAuth(request.auth);
  // Exclui as próprias ofertas do vendedor da listagem.
  const offers = await listAllOffers(request.auth.uid);


  return {
    data: offers,
  };
});
