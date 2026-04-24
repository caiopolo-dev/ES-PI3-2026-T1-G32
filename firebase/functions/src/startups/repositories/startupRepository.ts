// Autor: Gustavo Alves de Siqueira Costa
// Data: 23/04/2026
// Descrição: Acesso ao Firestore para busca de startups

import {db} from "../../shared/firebase";
import {Startup, EstagioStartup} from "../types";

const STARTUPS_COLLECTION = "startups";

export const startupRepository = {

  async findAll(estagio?: EstagioStartup): Promise<Startup[]> {
    let query: FirebaseFirestore.Query = db.collection(STARTUPS_COLLECTION);

    if (estagio) {
      query = query.where("estagio", "==", estagio);
    }

    const snapshot = await query.get();

    return snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Startup[];
  },

  async findById(id: string): Promise<Startup | null> {
    const doc = await db.collection(STARTUPS_COLLECTION).doc(id).get();

    if (!doc.exists) return null;

    return {id: doc.id, ...doc.data()} as Startup;
  },
};
