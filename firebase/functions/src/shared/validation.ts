// Autor: Gustavo Alves de Siqueira Costa
// Data: 11/05/2026
// Descrição: Funções de validação reutilizáveis entre os handlers

import {HttpsError} from "firebase-functions/v2/https";

/**
 * Asserts that the request is authenticated.
 * @param {unknown} auth The auth object from the request.
 */
export function requireAuth(auth: unknown): asserts auth {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }
}
