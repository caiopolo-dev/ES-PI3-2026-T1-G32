// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/04/2026
// Descrição: Handler para buscar todas as startups

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {startupRepository} from "../repositories/startupRepository";
import {EstagioStartup} from "../types";

// Função callable - o Flutter chama via
// FirebaseFunctions.instance.httpsCallable('getStartups')
// Aceita opcionalmente { estagio: 'nova' | 'em_operacao' | 'em_expansao' }
export const getStartups = onCall(async (request) => {
  try {
    // Pega o estágio enviado pelo Flutter (opcional)
    const estagio = request.data?.estagio as EstagioStartup | undefined;

    // Chama o repository que vai buscar no Firestore
    const startups = await startupRepository.findAll(estagio);

    // Retorna os dados direto, sem res.status()
    // pois onCall faz isso automaticamente
    return {
      success: true,
      data: startups,
    };
  } catch (error) {
    // onCall usa HttpsError em vez de res.status(500)
    throw new HttpsError("internal", "Erro ao buscar startups");
  }
});
