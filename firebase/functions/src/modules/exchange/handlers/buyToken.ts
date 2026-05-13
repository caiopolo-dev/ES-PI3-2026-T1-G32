// Autor: Rafael Mendes Valente
// Descrição: Handler para compra de tokens

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {FieldValue} from "firebase-admin/firestore";
import {exchangeRepository} from "../repositories/exchangeRepository";

export const buyToken = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  const {startupId, quantidade} = request.data;
  const uid = request.auth.uid;

  if (!startupId || !quantidade || quantidade <= 0) {
    throw new HttpsError("invalid-argument", "Dados inválidos");
  }

  const startupDoc = await exchangeRepository.getStartup(startupId);
  if (!startupDoc.exists) {
    throw new HttpsError("not-found", "Startup não encontrada");
  }

  const startup = startupDoc.data()!;
  const precoUnitario: number = startup.precoToken ?? 100;
  const total = precoUnitario * quantidade;

  const saldoAtual = await exchangeRepository.getSaldo(uid);
  if (saldoAtual < total) {
    throw new HttpsError("failed-precondition", "Saldo insuficiente");
  }

  await exchangeRepository.updateSaldo(uid, saldoAtual - total);

  const tokenDoc = await exchangeRepository.getTokenDoUsuario(uid, startupId);
  if (tokenDoc.exists) {
    const tokenAtual = tokenDoc.data()!;
    const qtdAnterior = tokenAtual.quantidade;
    const precoMedioAnterior = tokenAtual.precoMedio;
    const novaQtd = qtdAnterior + quantidade;
    const novoPrecoMedio =
      (precoMedioAnterior * qtdAnterior + precoUnitario * quantidade) / novaQtd;

    await exchangeRepository.updateTokenDoUsuario(uid, startupId, {
      quantidade: novaQtd,
      precoMedio: novoPrecoMedio,
      valorAtual: precoUnitario,
    });
  } else {
    await exchangeRepository.updateTokenDoUsuario(uid, startupId, {
      startupId,
      startupName: startup.nome,
      quantidade,
      precoMedio: precoUnitario,
      valorAtual: precoUnitario,
    });
  }

  const novoPreco = parseFloat((precoUnitario * 1.01).toFixed(2));
  await exchangeRepository.updateTokenPrice(startupId, novoPreco);

  await exchangeRepository.registrarTransacao({
    uid,
    startupId,
    startupName: startup.nome,
    tipo: "compra",
    quantidade,
    precoUnitario,
    total,
    criadoEm: FieldValue.serverTimestamp() as FirebaseFirestore.Timestamp,
  });

  return {
    success: true,
    message: "Compra realizada com sucesso",
    novoSaldo: saldoAtual - total,
    novoPrecoToken: novoPreco,
  };
});
