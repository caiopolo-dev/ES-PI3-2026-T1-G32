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

// Status de ofertas de token
export const OFFER_STATUS_OPEN = "open";

// Tipos de transação
export const TX_TYPE_BUY = "buy";
export const TX_TYPE_SELL = "sell";
export const TX_TYPE_RETURN = "return";
export const TX_TYPE_CANCEL_OFFER = "cancel_offer";
export const TX_TYPE_DEPOSIT = "deposit";

// Origem de transação
export const TX_SOURCE_OFFER = "offer";
export const TX_SOURCE_SELL_OFFER = "sell_offer";
export const TX_SOURCE_STARTUP = "startup";
