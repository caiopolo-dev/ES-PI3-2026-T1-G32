// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Retorna os dados do usuário autenticado a partir do Firestore

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";

export const getUserData = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  const uid = request.auth.uid;
  const doc = await getFirestore().collection("users").doc(uid).get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "Usuário não encontrado");
  }

  return doc.data();
});
