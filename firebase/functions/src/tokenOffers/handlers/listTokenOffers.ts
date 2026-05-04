// Caio Ferreir Polo - 25002823

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {listAllOffers} from "../repositories/offersRepository";

export const listOffers = onCall(async (request)=>{
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Usuário não autenticado"
    );
  }
  const offers = await listAllOffers(request.auth.uid);


  return {
    data: offers,
  };
});
