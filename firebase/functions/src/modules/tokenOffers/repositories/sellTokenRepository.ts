// Autor: Rafael Mendes Valente - RA: 25002875
// Descrição: Repository para criação de ofertas de venda de tokens

import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../../../shared/firebase";
import {
  USERS, STARTUPS, TOKEN_OFFERS, USER_TOKENS, PRICE_HISTORY,
  OFFER_STATUS_OPEN, TX_TYPE_SELL, TX_SOURCE_SELL_OFFER,
} from "../../../shared/collections";
import {updateTodaySnapshot} from
  "../../wallet/repositories/portfolioRepository";
import {FATOR_IMPACTO} from "../../../shared/tokenPricing";
import {
  CreateSellOfferParams,
  CreateSellOfferResult,
} from "../types/tokenOfferTypes";

/**
 * Creates a sell offer and locks the seller's tokens atomically.
 * @param {CreateSellOfferParams} params Offer parameters.
 * @return {Promise<CreateSellOfferResult>} Created offer data.
 */
export async function createSellOffer(
  params: CreateSellOfferParams
): Promise<CreateSellOfferResult> {
  const {startupId, sellerId, quantity, pricePerTokenCents} = params;

  const result = await db.runTransaction(async (transaction) => {
    const startupRef = db.collection(STARTUPS).doc(startupId);
    const userTokenRef = db
      .collection(USERS)
      .doc(sellerId)
      .collection(USER_TOKENS)
      .doc(startupId);

    const startupSnap = await transaction.get(startupRef);
    const userTokenSnap = await transaction.get(userTokenRef);

    if (!startupSnap.exists) {
      throw new HttpsError("not-found", "Startup não encontrada");
    }

    const startupData = startupSnap.data();

    if (!startupData) {
      throw new HttpsError("not-found", "Dados da startup não encontrados");
    }

    const startupName = String(startupData.nome ?? startupId);

    const userTokenData = userTokenSnap.data();
    const currentQty = Number(userTokenData?.quantidade ?? 0);
    const precoMedio = Number(userTokenData?.precoMedio ?? 0);
    const valorAtual = Number(userTokenData?.valorAtual ?? pricePerTokenCents);

    if (!userTokenSnap.exists || currentQty <= 0) {
      throw new HttpsError(
        "not-found",
        "Você não possui tokens desta startup"
      );
    }

    if (currentQty < quantity) {
      throw new HttpsError(
        "failed-precondition",
        "Quantidade insuficiente de tokens"
      );
    }

    const newQty = currentQty - quantity;

    // Bloqueia os tokens do vendedor
    if (newQty === 0) {
      transaction.delete(userTokenRef);
    } else {
      transaction.set(
        userTokenRef,
        {quantidade: newQty, updatedAt: FieldValue.serverTimestamp()},
        {merge: true}
      );
    }

    // Cria a oferta no balcão
    const offerRef = db.collection(TOKEN_OFFERS).doc();
    transaction.set(offerRef, {
      sellerId,
      startupId,
      startupName,
      amount: quantity,
      valorUnitarioCentavos: pricePerTokenCents,
      precoMedio,
      valorAtual,
      status: OFFER_STATUS_OPEN,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Oferta de venda aumenta a oferta disponível → pressão de baixa no preço
    const totalTokens = Number(startupData.totalTokens ?? 1000);
    const precoAtual = Number(startupData.precoToken ?? 100);
    const impacto = (quantity / totalTokens) * FATOR_IMPACTO;
    const novoPreco = Math.max(1, Math.round(precoAtual * (1 - impacto)));
    transaction.update(startupRef, {
      precoToken: novoPreco,
      precoTokenAnterior: precoAtual,
    });

    const priceHistoryRef = db
      .collection(STARTUPS).doc(startupId)
      .collection(PRICE_HISTORY).doc();
    transaction.set(priceHistoryRef, {
      price: novoPreco,
      type: TX_TYPE_SELL,
      source: TX_SOURCE_SELL_OFFER,
      quantity,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      offerId: offerRef.id,
      startupId,
      startupName,
      quantity,
      pricePerTokenCents,
    };
  });

  try {
    await updateTodaySnapshot(sellerId);
  } catch (e) {
    console.warn("updateTodaySnapshot failed (non-fatal):", e);
  }

  return result;
}
