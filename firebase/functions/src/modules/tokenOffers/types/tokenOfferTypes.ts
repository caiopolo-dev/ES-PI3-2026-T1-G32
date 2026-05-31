// Autor: Caio Ferreira Polo
// Descrição: Tipos e interfaces do domínio de ofertas de tokens

// Observações gerais:
// - Valores monetários são representados em centavos (inteiros).
// - Quantidades (`quantity`, `amount`) são inteiros que representam
//   unidades de token (não frações).
// - Tipos aqui descrevem payloads de sucesso retornados pelos
//   repositórios/handlers; erros são comunicados via `HttpsError`.

export type BuyTokenOfferParams = {
  offerId: string;
  buyerId: string;
  quantity: number;
};

export type BuyTokenOfferResult = {
  transactionId: string;
  offerId: string;
  startupId: string;
  quantity: number;
  // Preço por token em centavos (inteiro).
  pricePerTokenCents: number;
  // Total da transação em centavos (pricePerTokenCents * quantity).
  totalCents: number;
  remainingAmount: number;
};

export type CreateSellOfferParams = {
  startupId: string;
  sellerId: string;
  quantity: number;
  // Preço pedido por token, em centavos (inteiro).
  pricePerTokenCents: number;
};

export type CreateSellOfferResult = {
  offerId: string;
  startupId: string;
  startupName: string;
  quantity: number;
  // Preço pedido por token, em centavos (inteiro).
  pricePerTokenCents: number;
};

export type CancelSellOfferParams = {
  offerId: string;
  sellerId: string;
};

export type CancelSellOfferResult = {
  offerId: string;
  startupId: string;
  returnedAmount: number;
};
