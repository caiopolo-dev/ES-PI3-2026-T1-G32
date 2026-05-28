export type PortfolioTransaction = {
  id: string;
  type?: string;
  startupId?: string;
  quantity?: number;
  pricePerTokenCents?: number;
  marketPriceAfterCents?: number;
  totalCents?: number;
  createdAt?: FirebaseFirestore.Timestamp;
};

export type PortfolioHistoryPoint = {
  date: string | null;
  valueCents: number;
  investedCents: number;
  returnPercent: number;
};
