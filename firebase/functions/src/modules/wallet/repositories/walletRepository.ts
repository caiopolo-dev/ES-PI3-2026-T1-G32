// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Descrição: Repository da carteira do usuário

import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {db} from "../../../shared/firebase";
import {
  USERS, TRANSACTIONS, STARTUPS, WALLET, WALLET_SALDO, USER_TOKENS,
  PRICE_HISTORY, TxType,
} from "../../../shared/collections";

/**
 * Returns wallet balance and portfolio summary for a user.
 * @param {string} uid User ID.
 * @return {Promise<object>} Wallet data.
 */
export async function getWalletDataByUserId(uid: string) {
  const [walletDoc, tokenSnap] = await Promise.all([
    db.collection(USERS).doc(uid).collection(WALLET).doc(WALLET_SALDO).get(),
    db.collection(USERS).doc(uid).collection(USER_TOKENS).get(),
  ]);

  const saldo = Number(walletDoc.data()?.saldo ?? 0);

  let totalTokens = 0;
  let totalInvestido = 0;
  tokenSnap.docs.forEach((doc) => {
    const d = doc.data();
    const qty = Number(d.quantidade ?? 0);
    totalTokens += qty;
    totalInvestido += qty * Number(d.precoMedio ?? 0);
  });

  return {saldo, totalInvestido, totalTokens};
}

/**
 * Returns transaction history for a user (as buyer and as seller).
 * @param {string} uid User ID.
 * @return {Promise<object>} Transaction list.
 */
export async function getTransactionHistoryByUserId(uid: string) {
  const buyerSnap = await db
    .collection(TRANSACTIONS)
    .where("buyerId", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(50)
    .get();

  // Graceful fallback: if sellerId index is still building, skip sell records.
  let sellerSnap: FirebaseFirestore.QuerySnapshot | null = null;
  try {
    sellerSnap = await db
      .collection(TRANSACTIONS)
      .where("sellerId", "==", uid)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get();
  } catch (e) {
    console.warn("sellerId query failed (index may still be building):", e);
  }

  const fromBuyer = buyerSnap.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      type: data.type as string,
      startupId: data.startupId ?? null,
      startupName: data.startupName ?? null,
      quantity: Number(data.quantity ?? 0),
      pricePerTokenCents: Number(data.pricePerTokenCents ?? 0),
      totalCents: Number(data.totalCents ?? 0),
      createdAt: data.createdAt?.toDate?.()?.toISOString() ?? null,
    };
  });

  // Records where uid is the seller: override type to "sell" for display.
  const fromSeller = (sellerSnap?.docs ?? []).map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      type: TxType.SELL,
      startupId: data.startupId ?? null,
      startupName: data.startupName ?? null,
      quantity: Number(data.quantity ?? 0),
      pricePerTokenCents: Number(data.pricePerTokenCents ?? 0),
      totalCents: Number(data.totalCents ?? 0),
      createdAt: data.createdAt?.toDate?.()?.toISOString() ?? null,
    };
  });

  const all = [...fromBuyer, ...fromSeller].sort((a, b) => {
    if (!a.createdAt) return 1;
    if (!b.createdAt) return -1;
    return b.createdAt.localeCompare(a.createdAt);
  });

  return {transactions: all};
}

/**
 * Returns tokens held by a user aggregated from transaction history.
 * @param {string} uid User ID.
 * @return {Promise<object>} Token list.
 */
export async function getUserTokensByUserId(uid: string) {
  const tokenSnap = await db
    .collection(USERS)
    .doc(uid)
    .collection(USER_TOKENS)
    .get();

  if (tokenSnap.empty) return {tokens: []};

  const startupIds = tokenSnap.docs.map((doc) => doc.id);

  const startupDocs = await Promise.all(
    startupIds.map((id) => db.collection(STARTUPS).doc(id).get())
  );

  const startupMap: Record<string, FirebaseFirestore.DocumentData> = {};
  startupDocs.forEach((doc) => {
    if (doc.exists) {
      const d = doc.data();
      if (d) startupMap[doc.id] = d;
    }
  });

  // Same cutoff as startupRepository: Brazil time (UTC-3 = 03:00 UTC).
  const brazilNow = new Date(new Date().getTime() - 3 * 60 * 60 * 1000);
  const startOfDay = Timestamp.fromDate(new Date(Date.UTC(
    brazilNow.getUTCFullYear(),
    brazilNow.getUTCMonth(),
    brazilNow.getUTCDate(),
    3, 0, 0, 0
  )));
  const fechamentoMap: Record<string, number> = {};
  await Promise.all(
    startupIds.map(async (id) => {
      const snap = await db
        .collection(STARTUPS).doc(id)
        .collection(PRICE_HISTORY)
        .where("createdAt", "<", startOfDay)
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();
      if (!snap.empty) {
        fechamentoMap[id] = Number(snap.docs[0].data().price);
      }
    })
  );

  const tokens = tokenSnap.docs.map((doc) => {
    const d = doc.data();
    const startup = startupMap[doc.id] ?? {};
    const precoAtual = Number(startup.precoToken ?? d.valorAtual ?? 0);
    // Prefer daily closing price from history; fall back to last transaction.
    const rawAnterior = fechamentoMap[doc.id] ??
      Number(startup.precoTokenAnterior ?? 0);
    const ratio = precoAtual > 0 && rawAnterior > 0 ?
      rawAnterior / precoAtual : 1;
    const precoAnterior =
      ratio > 20 || ratio < 0.05 ? precoAtual : rawAnterior;
    return {
      startupId: doc.id,
      startupNome: startup.nome ?? "—",
      startupLogo: startup.logoUrl ?? null,
      quantidade: Number(d.quantidade ?? 0),
      precoMedio: Number(d.precoMedio ?? 0),
      valorAtual: precoAtual,
      precoAnterior,
    };
  });

  return {tokens};
}

/**
 * Adds amountCents to the user's wallet balance atomically
 * and records a deposit entry in the transaction history.
 * @param {string} uid User ID.
 * @param {number} amountCents Amount in cents to add.
 */
export async function addBalanceToWallet(uid: string, amountCents: number) {
  const walletRef = db
    .collection(USERS)
    .doc(uid)
    .collection(WALLET)
    .doc(WALLET_SALDO);

  const txRef = db.collection(TRANSACTIONS).doc();

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(walletRef);
    const current = Number(snap.data()?.saldo ?? 0);
    transaction.set(
      walletRef,
      {saldo: current + amountCents, updatedAt: FieldValue.serverTimestamp()},
      {merge: true}
    );
    transaction.set(txRef, {
      type: TxType.DEPOSIT,
      buyerId: uid,
      totalCents: amountCents,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
}
