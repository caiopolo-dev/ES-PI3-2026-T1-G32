// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Descrição: Repository da carteira do usuário

import {getFirestore} from "firebase-admin/firestore";

export async function getWalletDataByUserId(uid: string) {
  const db = getFirestore();

  const walletDoc = await db
    .collection("users")
    .doc(uid)
    .collection("wallet")
    .doc("saldo")
    .get();

  const saldo = Number(walletDoc.data()?.saldo ?? 0);

  const tokensSnap = await db
    .collection("userTokens")
    .where("userId", "==", uid)
    .limit(50)
    .get();

  let totalInvestido = 0;
  let totalTokens = 0;

  tokensSnap.docs.forEach((doc) => {
    const data = doc.data();

    const precoMedio = Number(data.precoMedio ?? 0);
    const quantidade = Number(data.quantidade ?? 0);

    totalInvestido += precoMedio * quantidade;
    totalTokens += quantidade;
  });

  return {
    saldo,
    totalInvestido,
    totalTokens,
  };
}

export async function getTransactionHistoryByUserId(uid: string) {
  const db = getFirestore();

  const snapshot = await db
    .collection("transactions")
    .where("userId", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(50)
    .get();

  const transactions = snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
    createdAt:
      doc.data().createdAt?.toDate?.()?.toISOString() ?? null,
  }));

  return {transactions};
}

export async function getUserTokensByUserId(uid: string) {
  const db = getFirestore();

  const snapshot = await db
    .collection("userTokens")
    .where("userId", "==", uid)
    .limit(50)
    .get();

  const tokens = await Promise.all(
    snapshot.docs.map(async (doc) => {
      const data = doc.data();

      const startupDoc = await db
        .collection("startups")
        .doc(data.startupId as string)
        .get();

      const startup = startupDoc.exists ? startupDoc.data() : {};

      return {
        id: doc.id,
        startupId: data.startupId,
        startupNome: startup?.nome ?? "—",
        startupLogo: startup?.logoUrl ?? null,
        quantidade: Number(data.quantidade ?? 0),
        precoMedio: Number(data.precoMedio ?? 0),
        valorAtual: Number(data.valorAtual ?? 0),
      };
    })
  );

  return {tokens};
}