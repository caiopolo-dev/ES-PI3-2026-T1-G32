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
