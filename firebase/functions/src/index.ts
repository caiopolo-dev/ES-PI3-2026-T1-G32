// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Ponto de entrada das Cloud Functions — inicializa o app Firebase e exporta todas as funções

import {initializeApp} from "firebase-admin/app";

initializeApp();

export {createUser, getUserData, checkUserExists} from "./users";
export {getStartups, getStartupById, createFaq, getFaqs} from "./startups";
export {listOffers, buyOffer} from "./tokenOffers";
export {getWalletInfo, getTransactionHistory, getUserTokens} from "./wallet";
