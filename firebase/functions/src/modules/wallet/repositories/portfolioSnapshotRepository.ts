// Autor: Gustavo Alves de Siqueira Costa
// Data: 28/05/2026
// Descrição: Salva/atualiza o snapshot diário do portfólio do usuário.
// Chamado após cada transação (compra, venda, cancelamento) e pelo job diário.

import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../../shared/firebase";
import {
  USERS,
  USER_TOKENS,
  STARTUPS,
  PORTFOLIO_HISTORY,
} from "../../../shared/collections";

/**
 * Atualiza o ponto de hoje em users/{uid}/portfolioHistory/{date}.
 * Usa startup.precoToken (mesma fonte que getUserTokens) para consistência.
 * @param {string} uid ID do usuário.
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
