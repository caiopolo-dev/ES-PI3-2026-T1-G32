// Autor: Rafael Mendes Valente
// Descrição: Tipos e interfaces do domínio de exchange

export interface Token {
  startupId: string;
  startupName: string;
  quantidade: number;
  precoMedio: number;
  valorAtual: number;
}

export interface Transacao {
  id?: string;
  uid: string;
  startupId: string;
  startupName: string;
  tipo: "compra" | "venda";
  quantidade: number;
  precoUnitario: number;
  total: number;
  criadoEm: FirebaseFirestore.Timestamp;
}

export interface WalletInfo {
  saldo: number;
  tokens: Token[];
}