// Autor: Rafael Mendes Valente
// Descrição: Repository para operações de exchange no Firestore

import {db} from "../../shared/firebase";
import {
  USERS,
  WALLET,
  WALLET_SALDO,
  USER_TOKENS,
  TOKEN_TRANSACTIONS,
  STARTUPS,
} from "../../shared/collections";
import {Transacao, Token} from "../types";

export const exchangeRepository = {

  async getSaldo(uid: string): Promise<number> {
    const doc = await db
      .collection(USERS)
      .doc(uid)
      .collection(WALLET)
      .doc(WALLET_SALDO)
      .get();
    return doc.exists ? (doc.data()?.saldo ?? 0) : 0;
  },

  async updateSaldo(uid: string, novoSaldo: number): Promise<void> {
    await db
      .collection(USERS)
      .doc(uid)
      .collection(WALLET)
      .doc(WALLET_SALDO)
      .update({saldo: novoSaldo});
  },

  async getTokenDoUsuario(uid: string, startupId: string) {
    return db
      .collection(USERS)
      .doc(uid)
      .collection(USER_TOKENS)
      .doc(startupId)
      .get();
  },

  async updateTokenDoUsuario(
    uid: string,
    startupId: string,
    data: Partial<Token>
  ): Promise<void> {
    await db
      .collection(USERS)
      .doc(uid)
      .collection(USER_TOKENS)
      .doc(startupId)
      .set(data, {merge: true});
  },

  async deleteTokenDoUsuario(uid: string, startupId: string): Promise<void> {
    await db
      .collection(USERS)
      .doc(uid)
      .collection(USER_TOKENS)
      .doc(startupId)
      .delete();
  },

  async listarTokensDoUsuario(uid: string): Promise<Token[]> {
    const snapshot = await db
      .collection(USERS)
      .doc(uid)
      .collection(USER_TOKENS)
      .get();
    return snapshot.docs.map((doc) => doc.data() as Token);
  },

  async registrarTransacao(transacao: Transacao): Promise<void> {
    await db.collection(TOKEN_TRANSACTIONS).add(transacao);
  },

  async listarTransacoes(uid: string): Promise<Transacao[]> {
    const snapshot = await db
      .collection(TOKEN_TRANSACTIONS)
      .where("uid", "==", uid)
      .orderBy("criadoEm", "desc")
      .get();
    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    } as Transacao));
  },

  async getStartup(startupId: string) {
    return db.collection(STARTUPS).doc(startupId).get();
  },

  async updateTokenPrice(startupId: string, novoPreco: number): Promise<void> {
    await db.collection(STARTUPS).doc(startupId).update({
      precoToken: novoPreco,
    });
  },
};
