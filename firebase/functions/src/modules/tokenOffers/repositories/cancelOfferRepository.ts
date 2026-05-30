// Autor: Caio Ferreira Polo
// Descrição: Repository para cancelamento de ofertas de venda de tokens

import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../../../shared/firebase";
import {
  USERS, TOKEN_OFFERS, USER_TOKENS, STARTUPS, PRICE_HISTORY, TRANSACTIONS,
  TX_TYPE_RETURN, TX_TYPE_CANCEL_OFFER, TX_SOURCE_SELL_OFFER,
} from "../../../shared/collections";
import {updateAllSnapshots} from
  "../../wallet/repositories/portfolioRepository";
import {
  CancelSellOfferParams,
  CancelSellOfferResult,
} from "../types/tokenOfferTypes";
import {FATOR_IMPACTO} from "../../../shared/tokenPricing";

/**
 * @param {CancelSellOfferParams} params
 * @return {Promise<CancelSellOfferResult>}
 */
export async function cancelOffer(
  params: CancelSellOfferParams
): Promise<CancelSellOfferResult> {
  const {offerId, sellerId} = params;

  // Created OUTSIDE runTransaction so retries reuse the same doc IDs
  const transactionRef = db.collection(TRANSACTIONS).doc();

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

    if (offerData.sellerId !== sellerId) {
      throw new HttpsError(
        "permission-denied",
        "Você não pode cancelar uma oferta de outro usuário"
      );
    }

    const startupId = String(offerData.startupId ?? "");
    const amount = Number(offerData.amount ?? 0);
    if (!startupId) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta sem startup vinculada"
      );
    }

    const precoMedio = Number(offerData.precoMedio ?? 0);

    if (!Number.isInteger(amount) || amount <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta sem tokens disponíveis para devolução"
      );
    }

    const startupRef = db.collection(STARTUPS).doc(startupId);
    const userTokenRef = db
      .collection(USERS)
      .doc(sellerId)
      .collection(USER_TOKENS)
      .doc(startupId);

    const [startupSnap, userTokenSnap] = await Promise.all([
      transaction.get(startupRef),
      transaction.get(userTokenRef),
    ]);

    const currentQty = Number(userTokenSnap.data()?.quantidade ?? 0);
    const newQty = currentQty + amount;
    const startupName = String(offerData.startupName ?? startupId);

    // Always increment quantidade; never overwrite precoMedio/valorAtual
    transaction.set(
      userTokenRef,
      {
        startupId,
        quantidade: newQty,
        ...(userTokenSnap.exists ? {} : {precoMedio}),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    // Record the return in transaction history (creates a new lot in portfolio)
    transaction.set(transactionRef, {
      type: TX_TYPE_RETURN,
      buyerId: sellerId,
      startupId,
      startupName,
      quantity: amount,
      pricePerTokenCents: precoMedio,
      totalCents: amount * precoMedio,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Revert the price impact that was applied when the offer was created
    const startupData = startupSnap.exists ? startupSnap.data() : null;
    if (startupData) {
      const totalTokens = Number(startupData.totalTokens ?? 1000);
      const precoAtual = Number(startupData.precoToken ?? 0);
      const impacto = (amount / totalTokens) * FATOR_IMPACTO;
      const precoRevertido = Math.round(precoAtual * (1 + impacto));

      transaction.update(startupRef, {
        precoToken: precoRevertido,
        precoTokenAnterior: precoAtual,
        updatedAt: FieldValue.serverTimestamp(),
      });

      const priceHistoryRef = db
        .collection(STARTUPS).doc(startupId)
        .collection(PRICE_HISTORY).doc();
      transaction.set(priceHistoryRef, {
        price: precoRevertido,
        type: TX_TYPE_CANCEL_OFFER,
        source: TX_SOURCE_SELL_OFFER,
        quantity: amount,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    transaction.delete(offerRef);

    return {
      offerId,
      startupId,
      returnedAmount: amount,
    };
  });

  try {
    await updateAllSnapshots();
  } catch (e) {
    console.warn("updateAllSnapshots failed (non-fatal):", e);
  }

  return result;
}
