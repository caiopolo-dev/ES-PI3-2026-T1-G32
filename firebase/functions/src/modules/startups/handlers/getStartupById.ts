// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/04/2026
// Descrição: Handler para buscar os detalhes de uma startup pelo ID

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {startupRepository} from "../repositories/startupRepository";

// Função callable - o Flutter chama via
// FirebaseFunctions.instance.httpsCallable('getStartupById')
// Requer { id: 'ecotrack' } no payload
export const getStartupById = onCall(async (request) => {
  // Valida se o ID foi enviado
  const id = request.data?.id;

  if (!id) {
    throw new HttpsError("invalid-argument", "ID da startup é obrigatório");
  }

  try {
    const startup = await startupRepository.findById(id, true);

    if (!startup) {
      throw new HttpsError("not-found", "Startup não encontrada");
    }

    return {
      success: true,
      data: startup,
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    // Em caso de erro inesperado retornamos `internal` para não vazar
    // detalhes internos à aplicação no payload da função.
    throw new HttpsError("internal", "Erro ao buscar startup");
  }
});
