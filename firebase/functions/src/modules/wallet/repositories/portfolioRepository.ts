// Autor: Caio Ferreira Polo - 25002823 / Gustavo Alves de Siqueira Costa
// Descrição: Repositório de portfólio — histórico e snapshots diários

import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../../shared/firebase";
import {
  USERS,
  STARTUPS,
  USER_TOKENS,
  PORTFOLIO_HISTORY,
} from "../../../shared/collections";

/**
 * Returns daily portfolio history points for a user, ordered by date ascending.
 * @param {string} uid User ID.
 * @return {Promise<object>} Daily portfolio points for the chart.
 */
export async function getPortfolioHistoryByUserId(uid: string) {
  const snap = await db
    .collection(USERS).doc(uid)
    .collection(PORTFOLIO_HISTORY)
    .orderBy("date", "asc")
    .get();

  const points = snap.docs.map((doc) => {
    const d = doc.data();
    return {
      date: d.date as string,
      returnPercent: d.returnPercent as number,
      investedCents: d.investedCents as number,
      valueCents: d.valueCents as number,
    };
  });

  return {points};
}

/**
 * Creates or updates today's portfolio snapshot for a user.
 * Reads current token positions and startup prices to compute
 * invested value, current value and return percentage.
 * Called after every transaction and by the daily scheduled job.
 * @param {string} uid User ID.
 * @return {Promise<void>}
 */
export async function updateTodaySnapshot(uid: string): Promise<void> {
  const tokensSnap = await db
    .collection(USERS).doc(uid)
    .collection(USER_TOKENS)
    .get();

  const activeLots = tokensSnap.docs.filter(
    (d) => Number(d.data().quantidade ?? 0) > 0
  );

  if (activeLots.length === 0) return;

  const startupSnaps = await Promise.all(
    activeLots.map((d) => db.collection(STARTUPS).doc(d.id).get())
  );

  let investedCents = 0;
  let valueCents = 0;

  activeLots.forEach((doc, i) => {
    const data = doc.data();
    const quantidade = Number(data.quantidade ?? 0);
    const precoMedio = Number(data.precoMedio ?? 0);
    const startupData = startupSnaps[i].data();
    const precoAtual = Number(startupData?.precoToken ?? data.valorAtual ?? 0);

    investedCents += quantidade * precoMedio;
    valueCents += quantidade * precoAtual;
  });

  if (investedCents <= 0) return;

  const returnPercent = ((valueCents - investedCents) / investedCents) * 100;
  const brazilNow = new Date(new Date().getTime() - 3 * 60 * 60 * 1000);
  const today = brazilNow.toISOString().slice(0, 10);

  await db
    .collection(USERS).doc(uid)
    .collection(PORTFOLIO_HISTORY)
    .doc(today)
    .set(
      {
        date: today,
        returnPercent,
        investedCents,
        valueCents,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
}
