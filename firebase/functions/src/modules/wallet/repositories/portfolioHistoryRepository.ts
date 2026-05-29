// Autor: Caio Ferreira Polo - 25002823
// Refatorado: lê de users/{uid}/portfolioHistory (snapshots persistidos).

import {db} from "../../../shared/firebase";
import {USERS, PORTFOLIO_HISTORY} from "../../../shared/collections";

/**
 * @param {string} uid ID do usuário.
 * @return {Promise<object>} Pontos diários do gráfico do portfólio.
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
