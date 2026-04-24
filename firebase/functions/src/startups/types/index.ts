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

export type EstagioStartup = "nova" | "em_operacao" | "em_expansao";

export interface Startup {
  id?: string;
  nome: string;
  descricao: string;
  estagio: EstagioStartup;
  setor: string;
  capitalAportado: number;
  totalTokens: number;
  precoToken: number;
  videos: string[];
  documentos: Documentos;
  socios: Socio[];
  conselho: MembroConselho[];
  status: string;
  createdAt?: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
}
