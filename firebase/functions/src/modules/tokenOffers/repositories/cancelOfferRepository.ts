// Autor: Caio Ferreira Polo
// Descrição: Repository para cancelamento de ofertas de venda de tokens

import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../../../shared/firebase";
import {
  USERS, TOKEN_OFFERS, USER_TOKENS,
} from "../../../shared/collections";
import {
  CancelSellOfferParams,
  CancelSellOfferResult,
} from "../types/tokenOfferTypes";

/**
 * @param {CancelSellOfferParams} params
 * @return {Promise<CancelSellOfferResult>}
 */
export async function cancelOffer(
  params: CancelSellOfferParams
): Promise<CancelSellOfferResult> {
  const {offerId, sellerId} = params;

  return db.runTransaction(async (transaction) => {
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
    const valorAtual = Number(
      offerData.valorAtual ?? offerData.valorUnitarioCentavos ?? 0
    );

    if (!Number.isInteger(amount) || amount <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta sem tokens disponíveis para devolução"
      );
    }

    const userTokenRef = db
      .collection(USERS)
      .doc(sellerId)
      .collection(USER_TOKENS)
      .doc(startupId);

    const userTokenSnap = await transaction.get(userTokenRef);
    const currentQty = Number(userTokenSnap.data()?.quantidade ?? 0);
    const newQty = currentQty + amount;


    transaction.set(
      userTokenRef,
      {
        startupId,
        quantidade: newQty,
        precoMedio,
        valorAtual,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    transaction.delete(offerRef);

    return {
      offerId,
      startupId,
      returnedAmount: amount,
    };
  });
}
