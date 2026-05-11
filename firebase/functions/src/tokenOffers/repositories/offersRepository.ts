// Caio Ferreira Polo - 25002823

import {FieldValue} from "firebase-admin/firestore";
import {db} from "../../shared/firebase";
import {HttpsError} from "firebase-functions/v2/https";

import {
  BuyTokenOfferParams,
  BuyTokenOfferResult,
} from "../types/tokenOfferTypes";

/**
 * Lists token offers from Firestore.
 * @param {string=} excludeSellerId User id to exclude from results.
 * @return {Promise<Array<object>>} List of token offers.
 */
export async function listAllOffers(excludeSellerId?: string) {
  const snapshot = await db.collection("token_offers").get();
  const offers = snapshot.docs
    .map((doc) => {
      const data = doc.data();

      return {
        offerId: doc.id,
        startupId: data.startupId,
        sellerId: data.sellerId,
        amount: data.amount,
        valorUnitarioCentavos: data.valorUnitarioCentavos,
      };
    })
    .filter((offer) => !excludeSellerId || offer.sellerId !== excludeSellerId);
  return offers;
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

  return db.runTransaction(async (transaction) => {
    const offerRef = db.collection("token_offers").doc(offerId);
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
      .collection("users")
      .doc(buyerId)
      .collection("wallet")
      .doc("saldo");

    const sellerWalletRef = db
      .collection("users")
      .doc(sellerId)
      .collection("wallet")
      .doc("saldo");

    const userTokenRef = db
      .collection("userTokens")
      .doc(`${buyerId}_${startupId}`);

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
    const newPrecoMedio = existingQty === 0 ?
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

    const transactionRef = db.collection("token_transactions").doc();

    transaction.set(transactionRef, {
      offerId,
      startupId,
      buyerId,
      sellerId,
      quantity,
      pricePerTokenCents,
      totalCents,
      type: "buy",
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
}
