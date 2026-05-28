// Autor: Caio Ferreira Polo - 25002823

import {db} from "../../../shared/firebase";
import {TRANSACTIONS, STARTUPS} from "../../../shared/collections";
import {
  PortfolioTransaction,
  PortfolioHistoryPoint,
} from "../types/portfolioHistoryTypes";

type PortfolioLot = {
  startupId: string;
  quantity: number;
  basePriceCents: number;
};

/**
 * @param {string} uid ID do usuário.
 * @return {Promise<object>} Pontos do gráfico do portfólio.
 */
export async function getPortfolioHistoryByUserId(uid: string) {
  const buyerSnap = await db
    .collection(TRANSACTIONS)
    .where("buyerId", "==", uid)
    .limit(100)
    .get();

  let sellerSnap: FirebaseFirestore.QuerySnapshot | null = null;

  try {
    sellerSnap = await db
      .collection(TRANSACTIONS)
      .where("sellerId", "==", uid)
      .limit(100)
      .get();
  } catch (e) {
    console.warn("sellerId query failed:", e);
  }

  const buyerTransactions: PortfolioTransaction[] = buyerSnap.docs.map(
    (doc) => {
      const data = doc.data();

      return {
        id: doc.id,
        type: data.type,
        startupId: data.startupId,
        quantity: data.quantity,
        pricePerTokenCents: data.pricePerTokenCents,
        totalCents: data.totalCents,
        createdAt: data.createdAt,
      };
    }
  );

  const sellerTransactions: PortfolioTransaction[] = (sellerSnap?.docs ?? [])
    .map((doc) => {
      const data = doc.data();

      return {
        id: doc.id,
        type: "sell",
        startupId: data.startupId,
        quantity: data.quantity,
        pricePerTokenCents: data.pricePerTokenCents,
        totalCents: data.totalCents,
        createdAt: data.createdAt,
      };
    });

  const transactions = [
    ...buyerTransactions,
    ...sellerTransactions,
  ].sort((a, b) => {
    const dateA = a.createdAt?.toDate().getTime() ?? 0;
    const dateB = b.createdAt?.toDate().getTime() ?? 0;

    return dateA - dateB;
  });

  const lots: PortfolioLot[] = [];
  const lastPriceByStartup: Record<string, number> = {};
  const points: PortfolioHistoryPoint[] = [];

  for (const tx of transactions) {
    const type = String(tx.type ?? "");
    const startupId = tx.startupId;
    const quantity = Number(tx.quantity ?? 0);
    const pricePerTokenCents = Number(tx.pricePerTokenCents ?? 0);

    if (!startupId || quantity <= 0 || pricePerTokenCents <= 0) {
      continue;
    }

    lastPriceByStartup[startupId] = pricePerTokenCents;

    if (type === "buy" || type === "return") {
      lots.push({
        startupId,
        quantity,
        basePriceCents: pricePerTokenCents,
      });
    }

    if (type === "sell") {
      removeQuantityFromLots(lots, startupId, quantity);
    }

    const point = calculatePoint(
      lots,
      lastPriceByStartup,
      tx.createdAt?.toDate().toISOString() ?? null
    );

    if (point.investedCents > 0) {
      points.push(point);
    }
  }

  const currentPrices = await getCurrentPricesByStartup(lots);

  const currentPoint = calculatePoint(
    lots,
    currentPrices,
    new Date().toISOString()
  );

  if (currentPoint.investedCents > 0) {
    points.push(currentPoint);
  }

  return {points};
}

/**
 * Remove quantidade vendida dos lotes usando FIFO simples.
 * @param {PortfolioLot[]} lots Lotes atuais.
 * @param {string} startupId ID da startup.
 * @param {number} quantity Quantidade vendida.
 */
function removeQuantityFromLots(
  lots: PortfolioLot[],
  startupId: string,
  quantity: number
) {
  let remaining = quantity;

  for (const lot of lots) {
    if (remaining <= 0) break;
    if (lot.startupId !== startupId) continue;
    if (lot.quantity <= 0) continue;

    const removed = Math.min(lot.quantity, remaining);
    lot.quantity -= removed;
    remaining -= removed;
  }
}

/**
 * Calcula um ponto do gráfico usando rentabilidade ponderada por lotes.
 * @param {PortfolioLot[]} lots Lotes atuais.
 * @param {Record<string, number>} prices Preços por startup.
 * @param {string | null} date Data do ponto.
 * @return {PortfolioHistoryPoint} Ponto do gráfico.
 */
function calculatePoint(
  lots: PortfolioLot[],
  prices: Record<string, number>,
  date: string | null
): PortfolioHistoryPoint {
  let investedCents = 0;
  let valueCents = 0;

  for (const lot of lots) {
    if (lot.quantity <= 0) continue;

    const currentPrice = prices[lot.startupId] ?? lot.basePriceCents;

    investedCents += lot.quantity * lot.basePriceCents;
    valueCents += lot.quantity * currentPrice;
  }

  const returnPercent = investedCents > 0 ?
    ((valueCents - investedCents) / investedCents) * 100 : 0;

  return {
    date,
    valueCents,
    investedCents,
    returnPercent,
  };
}

/**
 * Busca o preço atual das startups que aparecem nos lotes.
 * @param {PortfolioLot[]} lots Lotes atuais.
 * @return {Promise<Record<string, number>>} Preços atuais por startup.
 */
async function getCurrentPricesByStartup(lots: PortfolioLot[]) {
  const startupIds = [...new Set(
    lots
      .filter((lot) => lot.quantity > 0)
      .map((lot) => lot.startupId)
  )];

  const entries = await Promise.all(
    startupIds.map(async (startupId) => {
      const startupSnap = await db.collection(STARTUPS).doc(startupId).get();
      const startupData = startupSnap.data();
      const currentPrice = Number(startupData?.precoToken ?? 0);

      return [startupId, currentPrice] as const;
    })
  );

  return Object.fromEntries(entries);
}
