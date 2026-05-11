import {initializeApp} from "firebase-admin/app";

initializeApp();

export {createUser, getUserData, checkUserExists} from "./users";
export {getStartups, getStartupById, createFaq, getFaqs} from "./startups";
export {listOffers, buyOffer} from "./tokenOffers";
export {getWalletInfo, getTransactionHistory, getUserTokens} from "./wallet";
