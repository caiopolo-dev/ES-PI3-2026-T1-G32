// Autor: Gustavo Alves de Siqueira Costa
// Data: 23/04/2026
// Descrição: Interfaces TypeScript do domínio de startups
export interface Socio {
  nome: string;
  percentual: number;
}

export interface MembroConselho {
  nome: string;
  cargo: string;
}

export interface Documentos {
  sumarioExecutivo?: string;
  planoNegocios?: string;
}

export interface Photos {
  logoPhoto?: string;
}

export interface Assets {
  video?: string;
  photos?: Photos;
}

export type EstagioStartup = "nova" | "em_operacao" | "em_expansao";

export interface Faq {
  id?: string;
  pergunta: string;
  privada: boolean;
  email: string;
  nomeUsuario: string;
  criadoEm?: number;
}

// Observações sobre tipos do domínio:
// - `Faq.criadoEm` é representado como número (milissegundos desde epoch)
//   na camada de funções para facilitar serialização/ordenção no cliente.

export interface Startup {
  id: string;
  nome: string;
  descricao: string;
  estagio: EstagioStartup;
  setor: string;
  capitalAportado: number;
  totalTokens: number;
  precoToken: number;
  assets?: Assets;
  documentos: Documentos;
  socios: Socio[];
  conselho: MembroConselho[];
  status: string;
  createdAt?: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
  fechamentoOntemCentavos?: number;
  variacaoHojePercentual?: number;
  variacaoLabel?: string;
}

// Observações:
// - `precoToken` e `fechamentoOntemCentavos` usam centavos para evitar erros
//   de ponto flutuante; o cliente deve dividir por 100 para exibir em reais.
// - `createdAt`/`updatedAt` são `Timestamp` do Firestore e devem ser
//   convertidos para `Date`/milissegundos quando necessários no cliente.
