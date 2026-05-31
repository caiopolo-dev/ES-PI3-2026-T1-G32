// Caio Ferreira Polo - RA 25002823

import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../../../shared/firebase";
import {
  USERS,
  STARTUPS,
  TRANSACTIONS,
  WALLET,
  WALLET_SALDO,
  USER_TOKENS,
  PRICE_HISTORY,
  TxType, TxSource,
} from "../../../shared/collections";
import {calcularNovoPreco} from "../../../shared/tokenPricing";

/**
 * @param {object} params Dados necessários para realizar a compra.
 * @param {string} params.startupId ID da startup que terá tokens comprados.
 * @param {string} params.buyerId ID do usuário comprador.
 * @param {number} params.quantity Quantidade de tokens que quer comprar.
 * @return {Promise<object>} Dados da compra realizada.
 */
export async function buyStartupTokenDirectly(params: {
  startupId: string;
  buyerId: string;
  quantity: number;
}) {
  const {startupId, buyerId, quantity} = params;

  // Created OUTSIDE runTransaction so retries reuse the same doc ID
  const transactionRef = db.collection(TRANSACTIONS).doc();
  const priceHistoryRef = db
    .collection(STARTUPS).doc(startupId)
    .collection(PRICE_HISTORY).doc();

  const result = await db.runTransaction(async (transaction) => {
    const startupRef = db.collection(STARTUPS).doc(startupId);
    const buyerWalletRef = db
      .collection(USERS)
      .doc(buyerId)
      .collection(WALLET)
      .doc(WALLET_SALDO);

    const userTokenRef = db
      .collection(USERS)
      .doc(buyerId)
      .collection(USER_TOKENS)
      .doc(startupId);

    const startupSnap = await transaction.get(startupRef);
    const buyerWalletSnap = await transaction.get(buyerWalletRef);
    const userTokenSnap = await transaction.get(userTokenRef);

    // Valida existência da startup e dados necessários para compra direta.
    if (!startupSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Startup não encontrada"
      );
    }

    const startupData = startupSnap.data();

    if (!startupData) {
      throw new HttpsError(
        "not-found",
        "Dados da startup não encontrados"
      );
    }


    const startupName = String(startupData.nome ?? startupId);
    // Preço da startup é armazenado em centavos (inteiro).
    const pricePerTokenCents = Number(startupData.precoToken ?? 0);
    const availableTokens = Number(startupData.tokensDisponiveis ?? 0);

    if (pricePerTokenCents <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Preço do token inválido"
      );
    }

    if (availableTokens <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Essa startup não possui tokens disponíveis"
      );
    }

    if (quantity > availableTokens) {
      throw new HttpsError(
        "failed-precondition",
        "Quantidade maior que a disponível"
      );
    }
    // Calcula total em centavos para evitar imprecisão de ponto flutuante.
    const totalCents = quantity * pricePerTokenCents;
    const buyerBalance = Number(buyerWalletSnap.data()?.saldo ?? 0);

    if (buyerBalance < totalCents) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente"
      );
    }
    const newBuyerBalance = buyerBalance - totalCents;
    const newAvailableTokens = availableTokens - quantity;

    // Atualiza posição do comprador: recalcula `precoMedio` ponderado em centavos.
    const existingQty = Number(userTokenSnap.data()?.quantidade ?? 0);
    const existingPreco = Number(userTokenSnap.data()?.precoMedio ?? 0);
    const newQty = existingQty + quantity;

    let newPrecoMedio: number;

    if (existingQty === 0 || existingPreco === 0) {
      // existingPreco === 0: missing/corrupted data — reset to current price
      newPrecoMedio = pricePerTokenCents;
    } else {
      newPrecoMedio = Math.round(
        (existingQty * existingPreco + quantity * pricePerTokenCents) / newQty
      );
    }
    transaction.set(
      buyerWalletRef,
      {
        saldo: newBuyerBalance,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    const totalTokens = Number(startupData.totalTokens ?? 1000);
    const novoPreco = calcularNovoPreco(pricePerTokenCents, quantity, totalTokens, TxType.BUY);

    transaction.update(startupRef, {
      tokensDisponiveis: newAvailableTokens,
      precoToken: novoPreco,
      precoTokenAnterior: pricePerTokenCents,
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.set(priceHistoryRef, {
      price: novoPreco,
      type: TxType.BUY,
      source: TxSource.STARTUP,
      quantity,
      createdAt: FieldValue.serverTimestamp(),
    });

    transaction.set(
      userTokenRef,
      {
        buyerId,
        startupId,
        startupName,
        quantidade: newQty,
        precoMedio: newPrecoMedio,
        valorAtual: pricePerTokenCents,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );


    transaction.set(transactionRef, {
      startupId,
      startupName,
      buyerId,
      quantity,
      pricePerTokenCents,
      totalCents,
      type: TxType.BUY,
      source: TxSource.STARTUP,
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      transactionId: transactionRef.id,
      startupId,
      startupName,
      quantity,
      pricePerTokenCents,
      totalCents,
      remainingTokens: newAvailableTokens,
    };
  });


  return result;
}
