// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Acesso ao Firestore para busca de startups

import {Startup, EstagioStartup} from "../types";
import {db} from "../../../shared/firebase";
import {STARTUPS} from "../../../shared/collections";

export const startupRepository = {
  // Busca todas as startups, filtrando por estágio se informado
  async findAll(estagio?: EstagioStartup): Promise<Startup[]> {
    let query: FirebaseFirestore.Query = db.collection(STARTUPS);

    if (estagio) {
      query = query.where("estagio", "==", estagio);
    }

    const snapshot = await query.get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Startup[];
  },

  // Busca uma startup específica pelo ID do documento
  async findById(id: string): Promise<Startup | null> {
    const doc = await db.collection(STARTUPS).doc(id).get();

    if (!doc.exists) return null;

    return {id: doc.id, ...doc.data()} as Startup;
  },
};
