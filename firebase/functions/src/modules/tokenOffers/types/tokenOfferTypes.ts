// Autor: Caio Ferreira Polo
// Descrição: Tipos e interfaces do domínio de ofertas de tokens

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
  pricePerTokenCents: number;
  totalCents: number;
  remainingAmount: number;
};

export type CreateSellOfferParams = {
  startupId: string;
  sellerId: string;
  quantity: number;
  pricePerTokenCents: number;
};

export type CreateSellOfferResult = {
  offerId: string;
  startupId: string;
  startupName: string;
  quantity: number;
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
