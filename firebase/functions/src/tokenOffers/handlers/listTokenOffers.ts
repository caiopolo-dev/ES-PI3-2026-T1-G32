// Autor: Caio Ferreira Polo
// Descrição: Handler para listar as ofertas de tokens disponíveis no balcão

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {listAllOffers} from "../repositories/offersRepository";

export const listOffers = onCall(async (request)=>{
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuário não autenticado"
    );
  }
  // Passa o uid do usuário autenticado para que o repository exclua
  // as próprias ofertas do vendedor da listagem (usuário não compra de si mesmo).
  const offers = await listAllOffers(request.auth.uid);


  return {
    data: offers,
  };
});
