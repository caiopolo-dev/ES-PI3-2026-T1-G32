// Autor: Caio Ferreira Polo
// Descrição: Repository para ofertas de tokens e execução de compras no balcão

import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../../shared/firebase";
import {HttpsError} from "firebase-functions/v2/https";
import {
  USERS, STARTUPS, TOKEN_OFFERS, TRANSACTIONS,
  WALLET, WALLET_SALDO, USER_TOKENS, PRICE_HISTORY,
  OFFER_STATUS_OPEN, TX_TYPE_BUY, TX_SOURCE_OFFER,
} from "../../../shared/collections";
import {FATOR_IMPACTO} from "../../../shared/tokenPricing";

import {
  BuyTokenOfferParams,
  BuyTokenOfferResult,
} from "../types/tokenOfferTypes";

/**
 * Lists open sell offers created by a specific seller.
 * @param {string} sellerId Seller user ID.
 * @return {Promise<Array<object>>} List of the seller's offers.
 */
export async function listOffersBySeller(sellerId: string) {
  const snapshot = await db
    .collection(TOKEN_OFFERS)
    .where("sellerId", "==", sellerId)
    .get();

  const offers: Array<{
    offerId: string;
    startupId: string;
    startupName: string;
    amount: number;
    valorUnitarioCentavos: number;
    createdAt: string | null;
  }> = [];

  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    const status = String(data.status ?? OFFER_STATUS_OPEN);
    if (status !== OFFER_STATUS_OPEN) {
      return;
    }
    offers.push({
      offerId: doc.id,
      startupId: data.startupId,
      startupName: data.startupName,
      amount: data.amount,
      valorUnitarioCentavos: data.valorUnitarioCentavos,
      createdAt: data.createdAt?.toDate?.()?.toISOString() ?? null,
    });
  });

  return offers;
}

/**
 * Lists token offers from Firestore.
 * @param {string=} excludeSellerId User id to exclude from results.
 * @return {Promise<Array<object>>} List of token offers.
 */
export async function listAllOffers(excludeSellerId?: string) {
  const snapshot = await db.collection(TOKEN_OFFERS).get();
  const offers: Array<{
    offerId: string;
    startupId: string | undefined;
    startupName: string;
    sellerId: string;
    amount: number;
    valorUnitarioCentavos: number;
  }> = [];

  snapshot.docs.forEach((doc) => {
    const data = doc.data();
    const status = String(data.status ?? OFFER_STATUS_OPEN);
    if (status !== OFFER_STATUS_OPEN) {
      return;
    }
    const sellerId = data.sellerId as string;
    if (excludeSellerId && sellerId === excludeSellerId) {
      return;
    }
    offers.push({
      offerId: doc.id,
      startupId: data.startupId as string | undefined,
      startupName: (data.startupName ?? data.startupId) as string,
      sellerId,
      amount: data.amount as number,
      valorUnitarioCentavos: data.valorUnitarioCentavos as number,
    });
  });

  // Busca precoToken atual de cada startup para exibir preço de mercado.
  const uniqueStartupIds = [...new Set(
    offers.map((o) => o.startupId).filter(Boolean) as string[]
  )];

  const startupPrices: Record<string, number> = {};
  await Promise.all(
    uniqueStartupIds.map(async (id) => {
      const snap = await db.collection(STARTUPS).doc(id).get();
      if (snap.exists) {
        startupPrices[id] = Number(snap.data()?.precoToken ?? 0);
      }
    })
  );

  return offers.map((o) => ({
    ...o,
    precoMercadoCentavos: o.startupId ? (startupPrices[o.startupId] ?? 0) : 0,
  }));
}


/**
 * Buys tokens from a specific token offer.
 * @param {BuyTokenOfferParams} params Purchase parameters.
 * @return {Promise<BuyTokenOfferResult>} Purchase result.
 */
export async function buyTokenOffer(
  params: BuyTokenOfferParams
): Promise<BuyTokenOfferResult> {
  const {offerId, buyerId, quantity} = params;

  // Created OUTSIDE runTransaction so retries reuse the same doc IDs
  const transactionRef = db.collection(TRANSACTIONS).doc();

  // Toda a operação é atômica: débito do comprador, crédito do vendedor,
  // atualização da oferta e registro da transação acontecem juntos ou falham.
  const result = await db.runTransaction(async (transaction) => {
    const offerRef = db.collection(TOKEN_OFFERS).doc(offerId);
    const offerSnap = await transaction.get(offerRef);


    if (!offerSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Oferta não encontrada"
      );
    }

    const offerData = offerSnap.data();

    if (!offerData) {
      throw new HttpsError(
        "not-found",
        "Dados da oferta não encontrados"
      );
    }

    const status = String(offerData.status ?? OFFER_STATUS_OPEN);
    if (status !== OFFER_STATUS_OPEN) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta não está ativa"
      );
    }

    const sellerId = offerData.sellerId;
    const startupId = offerData.startupId;
    const availableAmount = Number(offerData.amount ?? 0);
    const pricePerTokenCents = Number(
      offerData.valorUnitarioCentavos ?? 0
    );

    if (!sellerId || !startupId) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta inválida"
      );
    }

    const startupRef = db.collection(STARTUPS).doc(startupId);
    const startupSnap = await transaction.get(startupRef);

    if (sellerId === buyerId) {
      throw new HttpsError(
        "failed-precondition",
        "Você não pode comprar sua própria oferta"
      );
    }

    if (quantity <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "Quantidade inválida"
      );
    }

    if (availableAmount <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Essa oferta não possui tokens disponíveis"
      );
    }

    if (quantity > availableAmount) {
      throw new HttpsError(
        "failed-precondition",
        "Quantidade maior que a disponível"
      );
    }

    if (pricePerTokenCents <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Preço da oferta inválido"
      );
    }

    const totalCents = quantity * pricePerTokenCents;

    const buyerWalletRef = db
      .collection(USERS)
      .doc(buyerId)
      .collection(WALLET)
      .doc(WALLET_SALDO);

    const sellerWalletRef = db
      .collection(USERS)
      .doc(sellerId)
      .collection(WALLET)
      .doc(WALLET_SALDO);

    const userTokenRef = db
      .collection(USERS)
      .doc(buyerId)
      .collection(USER_TOKENS)
      .doc(startupId);

    const buyerWalletSnap = await transaction.get(buyerWalletRef);
    const sellerWalletSnap = await transaction.get(sellerWalletRef);
    const userTokenSnap = await transaction.get(userTokenRef);

    const buyerBalance = Number(buyerWalletSnap.data()?.saldo ?? 0);
    const sellerBalance = Number(sellerWalletSnap.data()?.saldo ?? 0);

    if (buyerBalance < totalCents) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente"
      );
    }

    const newOfferAmount = availableAmount - quantity;

    transaction.set(
      buyerWalletRef,
      {
        saldo: buyerBalance - totalCents,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    transaction.set(
      sellerWalletRef,
      {
        saldo: sellerBalance + totalCents,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    if (newOfferAmount === 0) {
      transaction.delete(offerRef);
    } else {
      transaction.update(offerRef, {
        amount: newOfferAmount,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    const existingQty = Number(userTokenSnap.data()?.quantidade ?? 0);
    const existingPreco = Number(userTokenSnap.data()?.precoMedio ?? 0);
    const newQty = existingQty + quantity;
    // Preço médio ponderado entre posição anterior e nova compra.
    // existingPreco === 0 guarda contra dado corrompido (evita média errada).
    const newPrecoMedio = existingQty === 0 || existingPreco === 0 ?
      pricePerTokenCents :
      Math.round(
        (existingQty * existingPreco + quantity * pricePerTokenCents) / newQty
      );

    transaction.set(
      userTokenRef,
      {
        buyerId,
        startupId,
        quantidade: newQty,
        precoMedio: newPrecoMedio,
        valorAtual: pricePerTokenCents,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    const startupData = startupSnap.data();
    if (startupData) {
      const totalTokens = Number(startupData.totalTokens ?? 1000);
      const precoAtual = Number(startupData.precoToken ?? 0);
      const impacto = (quantity / totalTokens) * FATOR_IMPACTO;
      const novoPreco = Math.round(precoAtual * (1 + impacto));
      transaction.update(startupRef, {
        precoToken: novoPreco,
        precoTokenAnterior: precoAtual,
      });

      const priceHistoryRef = db
        .collection(STARTUPS).doc(startupId as string)
        .collection(PRICE_HISTORY).doc();
      transaction.set(priceHistoryRef, {
        price: novoPreco,
        type: TX_TYPE_BUY,
        source: TX_SOURCE_OFFER,
        quantity,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    transaction.set(transactionRef, {
      offerId,
      startupId,
      startupName: offerData.startupName ?? startupId,
      buyerId,
      sellerId,
      quantity,
      pricePerTokenCents,
      totalCents,
      type: TX_TYPE_BUY,
      source: TX_SOURCE_OFFER,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      transactionId: transactionRef.id,
      offerId,
      startupId,
      quantity,
      pricePerTokenCents,
      totalCents,
      remainingAmount: newOfferAmount,
    };
  });


  return result;
}
