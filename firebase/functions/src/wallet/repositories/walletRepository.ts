// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Descrição: Repository da carteira do usuário

import {db} from "../../shared/firebase";

/**
 * Returns wallet balance and portfolio summary for a user.
 * @param {string} uid User ID.
 * @return {Promise<object>} Wallet data.
 */
export async function getWalletDataByUserId(uid: string) {
  const [walletDoc, txSnap] = await Promise.all([
    db.collection("users").doc(uid).collection("wallet").doc("saldo").get(),
    db.collection("token_transactions")
      .where("buyerId", "==", uid)
      .where("type", "==", "buy")
      .get(),
  ]);

  const saldo = Number(walletDoc.data()?.saldo ?? 0);

  let totalInvestido = 0;
  let totalTokens = 0;

  txSnap.docs.forEach((doc) => {
    const data = doc.data();
    totalInvestido += Number(data.totalCents ?? 0);
    totalTokens += Number(data.quantity ?? 0);
  });

  return {saldo, totalInvestido, totalTokens};
}

/**
 * Returns transaction history for a user.
 * @param {string} uid User ID.
 * @return {Promise<object>} Transaction list.
 */
export async function getTransactionHistoryByUserId(uid: string) {
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

/**
 * Returns tokens held by a user aggregated from transaction history.
 * @param {string} uid User ID.
 * @return {Promise<object>} Token list.
 */
export async function getUserTokensByUserId(uid: string) {
  const txSnap = await db
    .collection("token_transactions")
    .where("buyerId", "==", uid)
    .where("type", "==", "buy")
    .get();

  if (txSnap.empty) return {tokens: []};

  const portfolioMap: Record<string, {quantidade: number; totalCost: number}> =
    {};

  txSnap.docs.forEach((doc) => {
    const d = doc.data();
    const sid = d.startupId as string;
    const qty = Number(d.quantity ?? 0);
    const price = Number(d.pricePerTokenCents ?? 0);
    if (!portfolioMap[sid]) portfolioMap[sid] = {quantidade: 0, totalCost: 0};
    portfolioMap[sid].quantidade += qty;
    portfolioMap[sid].totalCost += qty * price;
  });

  const startupIds = Object.keys(portfolioMap);

  const startupDocs = await Promise.all(
    startupIds.map((id) => db.collection("startups").doc(id).get())
  );

  const startupMap: Record<string, FirebaseFirestore.DocumentData> = {};
  startupDocs.forEach((doc) => {
    if (doc.exists) {
      const d = doc.data();
      if (d) startupMap[doc.id] = d;
    }
  });

  const tokens = startupIds.map((startupId) => {
    const {quantidade, totalCost} = portfolioMap[startupId];
    const startup = startupMap[startupId] ?? {};
    const precoMedio = quantidade > 0 ?
      Math.round(totalCost / quantidade) :
      0;
    return {
      startupId,
      startupNome: startup.nome ?? "—",
      startupLogo: startup.logoUrl ?? null,
      quantidade,
      precoMedio,
      valorAtual: precoMedio,
    };
  });

  return {tokens};
}
