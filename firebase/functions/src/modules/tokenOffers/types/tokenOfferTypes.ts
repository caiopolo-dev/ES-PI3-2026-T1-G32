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
