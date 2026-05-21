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
  variacaoLabel?: string;
}
