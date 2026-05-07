// Caio Ferreira Polo - 25002823
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";

export const getWalletBalance = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  const doc = await getFirestore()
    .collection("users")
    .doc(request.auth.uid)
    .collection("wallet")
    .doc("saldo")
    .get();

  const saldo = (doc.data()?.saldo as number) ?? 0;

  return {saldo};
});
