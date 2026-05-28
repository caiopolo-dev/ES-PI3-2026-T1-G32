// Autor: Caio Ferreira Polo - 25002823

import {db} from "../../../shared/firebase";
import {
  TRANSACTIONS,
  STARTUPS,
  PRICE_HISTORY,
} from "../../../shared/collections";
import {
  PortfolioTransaction,
  PortfolioHistoryPoint,
} from "../types/portfolioHistoryTypes";

type PortfolioLot = {
  startupId: string;
  quantity: number;
  basePriceCents: number;
};

type StartupPricePoint = {
  price: number;
  createdAt: Date;
};

/**
 * @param {string} uid ID do usuário.
 * @return {Promise<object>} Pontos diários do gráfico do portfólio.
 */
export async function getPortfolioHistoryByUserId(uid: string) {
  const transactions = await getUserTransactions(uid);

  if (transactions.length === 0) {
    return {points: []};
  }

  const firstDate = transactions[0].createdAt?.toDate();
  if (!firstDate) {
    return {points: []};
  }

  const startupIds = getStartupIdsFromTransactions(transactions);
  const priceHistoryByStartup = await getPriceHistoryByStartup(startupIds);

  const startDay = startOfLocalDay(firstDate);
  const today = startOfLocalDay(new Date());

  const points: PortfolioHistoryPoint[] = [];
  const lots: PortfolioLot[] = [];

  let transactionIndex = 0;

  for (
    let currentDay = new Date(startDay);
    currentDay <= today;
    currentDay = addDays(currentDay, 1)
  ) {
    const endOfDay = endOfLocalDay(currentDay);

    while (
      transactionIndex < transactions.length &&
      isTransactionUntil(transactions[transactionIndex], endOfDay)
    ) {
      applyTransactionToLots(lots, transactions[transactionIndex]);
      transactionIndex++;
    }

    const point = calculateDailyPoint(
      lots,
      priceHistoryByStartup,
      endOfDay
    );

    if (point.investedCents > 0) {
      points.push({
        date: currentDay.toISOString(),
        valueCents: point.valueCents,
        investedCents: point.investedCents,
        returnPercent: point.returnPercent,
      });
    }
  }

  return {points};
}

/**
 * Busca as transações do usuário como comprador e vendedor.
 * @param {string} uid ID do usuário.
 * @return {Promise<PortfolioTransaction[]>} Transações ordenadas por data.
 */
async function getUserTransactions(uid: string):
  Promise<PortfolioTransaction[]> {
  const buyerSnap = await db
    .collection(TRANSACTIONS)
    .where("buyerId", "==", uid)
    .limit(300)
    .get();

  let sellerSnap: FirebaseFirestore.QuerySnapshot | null = null;

  try {
    sellerSnap = await db
      .collection(TRANSACTIONS)
      .where("sellerId", "==", uid)
      .limit(300)
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
        marketPriceAfterCents: data.marketPriceAfterCents,
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
        marketPriceAfterCents: data.marketPriceAfterCents,
        totalCents: data.totalCents,
        createdAt: data.createdAt,
      };
    });

  return [
    ...buyerTransactions,
    ...sellerTransactions,
  ].sort((a, b) => {
    const dateA = a.createdAt?.toDate().getTime() ?? 0;
    const dateB = b.createdAt?.toDate().getTime() ?? 0;

    return dateA - dateB;
  });
}

/**
 * @param {PortfolioTransaction[]} transactions Transações.
 * @return {string[]} IDs únicos de startups.
 */
function getStartupIdsFromTransactions(transactions: PortfolioTransaction[]) {
  return [...new Set(
    transactions
      .map((tx) => tx.startupId)
      .filter((id): id is string => Boolean(id))
  )];
}

/**
 * Busca todo o histórico de preço das startups envolvidas.
 * @param {string[]} startupIds IDs das startups.
 * @return {Promise<Record<string, StartupPricePoint[]>>} Histórico por startup.
 */
async function getPriceHistoryByStartup(startupIds: string[]) {
  const entries = await Promise.all(
    startupIds.map(async (startupId) => {
      const snapshot = await db
        .collection(STARTUPS)
        .doc(startupId)
        .collection(PRICE_HISTORY)
        .orderBy("createdAt", "asc")
        .limit(500)
        .get();

      const prices: StartupPricePoint[] = snapshot.docs
        .map((doc) => {
          const data = doc.data();
          const createdAt = data.createdAt?.toDate?.();

          if (!createdAt) return null;

          return {
            price: Number(data.price ?? 0),
            createdAt,
          };
        })
        .filter((item): item is StartupPricePoint => {
          return item !== null && item.price > 0;
        });

      return [startupId, prices] as const;
    })
  );

  return Object.fromEntries(entries);
}

/**
 * Aplica uma transação nos lotes atuais.
 * @param {PortfolioLot[]} lots Lotes atuais.
 * @param {PortfolioTransaction} tx Transação.
 */
function applyTransactionToLots(
  lots: PortfolioLot[],
  tx: PortfolioTransaction
) {
  const type = String(tx.type ?? "");
  const startupId = tx.startupId;
  const quantity = Number(tx.quantity ?? 0);
  const pricePerTokenCents = Number(tx.pricePerTokenCents ?? 0);

  if (!startupId || quantity <= 0 || pricePerTokenCents <= 0) {
    return;
  }

  const basePriceCents = Number(
    tx.marketPriceAfterCents ?? pricePerTokenCents
  );

  if (type === "buy" || type === "return") {
    lots.push({
      startupId,
      quantity,
      basePriceCents,
    });
  }

  if (type === "sell") {
    removeQuantityFromLots(lots, startupId, quantity);
  }
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
 * Calcula o ponto diário do portfólio.
 * @param {PortfolioLot[]} lots Lotes atuais.
 * @param {Record<string, StartupPricePoint[]>} priceHistory Histórico de preço.
 * @param {Date} endOfDay Final do dia.
 * @return {Omit<PortfolioHistoryPoint, "date">} Dados calculados.
 */
function calculateDailyPoint(
  lots: PortfolioLot[],
  priceHistory: Record<string, StartupPricePoint[]>,
  endOfDay: Date
) {
  let investedCents = 0;
  let valueCents = 0;

  for (const lot of lots) {
    if (lot.quantity <= 0) continue;

    const closingPrice = getClosingPriceForDay(
      priceHistory[lot.startupId] ?? [],
      endOfDay,
      lot.basePriceCents
    );

    investedCents += lot.quantity * lot.basePriceCents;
    valueCents += lot.quantity * closingPrice;
  }

  const returnPercent = investedCents > 0 ?
    ((valueCents - investedCents) / investedCents) * 100 :
    0;

  return {
    valueCents,
    investedCents,
    returnPercent,
  };
}

/**
 * Pega o último preço conhecido até o final do dia.
 * @param {StartupPricePoint[]} prices Histórico de preços.
 * @param {Date} endOfDay Final do dia.
 * @param {number} fallbackPrice Preço fallback.
 * @return {number} Preço de fechamento do dia.
 */
function getClosingPriceForDay(
  prices: StartupPricePoint[],
  endOfDay: Date,
  fallbackPrice: number
) {
  let closingPrice = fallbackPrice;

  for (const item of prices) {
    if (item.createdAt.getTime() <= endOfDay.getTime()) {
      closingPrice = item.price;
    } else {
      break;
    }
  }

  return closingPrice;
}

/**
 * @param {PortfolioTransaction} tx Transação.
 * @param {Date} endOfDay Final do dia.
 * @return {boolean} Se a transação ocorreu até o final do dia.
 */
function isTransactionUntil(
  tx: PortfolioTransaction,
  endOfDay: Date
) {
  const createdAt = tx.createdAt?.toDate();
  if (!createdAt) return false;

  return createdAt.getTime() <= endOfDay.getTime();
}

/**
 * @param {Date} date Data.
 * @return {Date} Início do dia local.
 */
function startOfLocalDay(date: Date) {
  return new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate()
  );
}

/**
 * @param {Date} date Data.
 * @return {Date} Final do dia local.
 */
function endOfLocalDay(date: Date) {
  return new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    23,
    59,
    59,
    999
  );
}

/**
 * @param {Date} date Data.
 * @param {number} days Dias para adicionar.
 * @return {Date} Nova data.
 */
function addDays(date: Date, days: number) {
  return new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate() + days
  );
}
