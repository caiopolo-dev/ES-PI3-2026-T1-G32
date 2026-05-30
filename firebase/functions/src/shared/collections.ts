// Autor: Gustavo Alves de Siqueira Costa
// Data: 11/05/2026
// Descrição: Nomes das coleções do Firestore — fonte única de verdade

// Coleções raiz
export const USERS = "users";
export const STARTUPS = "startups";
export const TOKEN_OFFERS = "token_offers";
export const TRANSACTIONS = "transactions";

// Subcoleções e documentos fixos
export const WALLET = "wallet";
export const WALLET_SALDO = "saldo";
export const USER_TOKENS = "tokens";
export const FAQS = "faqs";
export const PRICE_HISTORY = "priceHistory";
export const PORTFOLIO_HISTORY = "portfolioHistory";

// Tipos de transação
export enum TxType {
  BUY = "buy",
  SELL = "sell",
  RETURN = "return",
  CANCEL_OFFER = "cancel_offer",
  DEPOSIT = "deposit",
}

// Origem de transação
export enum TxSource {
  OFFER = "offer",
  SELL_OFFER = "sell_offer",
  STARTUP = "startup",
}
