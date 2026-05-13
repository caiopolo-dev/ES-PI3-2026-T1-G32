// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Retorna os dados do usuário autenticado a partir do Firestore

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getUserById} from "../repositories/userRepository";
import {requireAuth} from "../../../shared/validation";

export const getUserData = onCall(async (request) => {
  requireAuth(request.auth);

  const uid = request.auth.uid;
  const doc = await getUserById(uid);

  if (!doc.exists) {
    throw new HttpsError("not-found", "Usuário não encontrado");
  }

  return doc.data();
});
