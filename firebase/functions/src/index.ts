// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Ponto de entrada — inicializa o Firebase e exporta as funções

import {initializeApp} from "firebase-admin/app";

initializeApp();

export {createUser, getUserData, checkUserExists} from "./modules/users";
export {getStartups, getStartupById, createFaq, getFaqs}
  from "./modules/startups";
export {listOffers, listMyOffers, buyOffer, buyStartupToken, createSellOffer}
  from "./modules/tokenOffers";
export {getWalletInfo, getTransactionHistory, getUserTokens, addBalance}
  from "./modules/wallet";
