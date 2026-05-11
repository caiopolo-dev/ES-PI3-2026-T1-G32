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
    .where("buyerId", "==", uid)
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

  return {saldo, totalInvestido, totalTokens};
}

export async function getTransactionHistoryByUserId(uid: string) {
  const db = getFirestore();

  const snapshot = await db
    .collection("token_transactions")
    .where("buyerId", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(50)
    .get();

  const transactions = snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      type: data.type,
      startupId: data.startupId,
      quantity: Number(data.quantity ?? 0),
      totalCents: Number(data.totalCents ?? 0),
      createdAt: data.createdAt?.toDate?.()?.toISOString() ?? null,
    };
  });

  return {transactions};
}

export async function getUserTokensByUserId(uid: string) {
  const db = getFirestore();

  const snapshot = await db
    .collection("userTokens")
    .where("buyerId", "==", uid)
    .limit(50)
    .get();

  const startupIds = [
    ...new Set(snapshot.docs.map((doc) => doc.data().startupId as string)),
  ];

  const startupDocs = await Promise.all(
    startupIds.map((id) => db.collection("startups").doc(id).get())
  );

  const startupMap: Record<string, FirebaseFirestore.DocumentData> = {};
  startupDocs.forEach((doc) => {
    if (doc.exists) startupMap[doc.id] = doc.data()!;
  });

  const tokens = snapshot.docs.map((doc) => {
    const data = doc.data();
    const startup = startupMap[data.startupId] ?? {};
    return {
      id: doc.id,
      startupId: data.startupId,
      startupNome: startup.nome ?? "—",
      startupLogo: startup.logoUrl ?? null,
      quantidade: Number(data.quantidade ?? 0),
      precoMedio: Number(data.precoMedio ?? 0),
      valorAtual: Number(data.valorAtual ?? 0),
    };
  });

  return {tokens};
}