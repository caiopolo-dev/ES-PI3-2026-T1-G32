// Autor: Rafael Mendes Valente
// Descrição: Handler para venda de tokens

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {FieldValue} from "firebase-admin/firestore";
import {exchangeRepository} from "../repositories/exchangeRepository";

export const sellToken = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  const {startupId, quantidade} = request.data;
  const uid = request.auth.uid;

  if (!startupId || !quantidade || quantidade <= 0) {
    throw new HttpsError("invalid-argument", "Dados inválidos");
  }

  const tokenDoc = await exchangeRepository.getTokenDoUsuario(uid, startupId);
  if (!tokenDoc.exists) {
    throw new HttpsError("not-found", "Você não possui tokens desta startup");
  }

  const tokenAtual = tokenDoc.data()!;
  if (tokenAtual.quantidade < quantidade) {
    throw new HttpsError(
      "failed-precondition",
      "Quantidade insuficiente de tokens"
    );
  }

  const startupDoc = await exchangeRepository.getStartup(startupId);
  const startup = startupDoc.data()!;
  const precoUnitario: number = startup.precoToken ?? 100;
  const total = precoUnitario * quantidade;

  const saldoAtual = await exchangeRepository.getSaldo(uid);
  await exchangeRepository.updateSaldo(uid, saldoAtual + total);

  const novaQtd = tokenAtual.quantidade - quantidade;
  if (novaQtd === 0) {
    await exchangeRepository.deleteTokenDoUsuario(uid, startupId);
  } else {
    await exchangeRepository.updateTokenDoUsuario(uid, startupId, {
      quantidade: novaQtd,
      valorAtual: precoUnitario,
    });
  }

  const novoPreco = parseFloat((precoUnitario * 0.99).toFixed(2));
  await exchangeRepository.updateTokenPrice(startupId, novoPreco);

  await exchangeRepository.registrarTransacao({
    uid,
    startupId,
    startupName: startup.nome,
    tipo: "venda",
    quantidade,
    precoUnitario,
    total,
    criadoEm: FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
  });

  return {
    success: true,
    message: "Venda realizada com sucesso",
    novoSaldo: saldoAtual + total,
    novoPrecoToken: novoPreco,
  };
});
