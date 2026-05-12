// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Ponto de entrada — inicializa o Firebase e exporta as funções

import {initializeApp} from "firebase-admin/app";

initializeApp();

export {createUser, getUserData, checkUserExists} from "./modules/users";
export {getStartups, getStartupById, createFaq, getFaqs}
  from "./modules/startups";
export {listOffers, buyOffer} from "./modules/tokenOffers";
export {getWalletInfo, getTransactionHistory, getUserTokens}
  from "./modules/wallet";
