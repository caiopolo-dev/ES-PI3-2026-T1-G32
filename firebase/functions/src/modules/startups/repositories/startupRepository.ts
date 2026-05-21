// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Acesso ao Firestore para busca de startups

import {Timestamp} from "firebase-admin/firestore";
import {Startup, EstagioStartup} from "../types";
import {db} from "../../../shared/firebase";
import {STARTUPS, PRICE_HISTORY} from "../../../shared/collections";

export const startupRepository = {
  async findAll(
    estagio?: EstagioStartup,
    includeDailyVariation = false
  ): Promise<Startup[]> {
    let query: FirebaseFirestore.Query = db.collection(STARTUPS);

    if (estagio) {
      query = query.where("estagio", "==", estagio);
    }

    const snapshot = await query.get();
    const startups = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Startup[];

    if (!includeDailyVariation) return startups;

    // Início do dia UTC — referência para "fechamento de ontem"
    const now = new Date();
    const startOfDay = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())
    );
    const startOfDayTs = Timestamp.fromDate(startOfDay);

    await Promise.all(
      startups.map(async (startup) => {
        // Tenta: fechamento de ontem (variação diária real)
        const snap = await db
          .collection(STARTUPS).doc(startup.id)
          .collection(PRICE_HISTORY)
          .where("createdAt", "<", startOfDayTs)
          .orderBy("createdAt", "desc")
          .limit(1)
          .get();

        if (!snap.empty) {
          startup.fechamentoOntemCentavos =
            snap.docs[0].data().price as number;
          startup.variacaoLabel = "hoje";
          return;
        }

        // Fallback: precoTokenAnterior do doc (última transação)
        const s = startup as unknown as Record<string, unknown>;
        const anterior = s.precoTokenAnterior;
        if (typeof anterior === "number" && anterior > 0) {
          startup.fechamentoOntemCentavos = anterior;
          startup.variacaoLabel = "última transação";
        }
      })
    );

    return startups;
  },

  // Busca uma startup específica pelo ID do documento
  async findById(id: string): Promise<Startup | null> {
    const doc = await db.collection(STARTUPS).doc(id).get();

    if (!doc.exists) return null;

    return {id: doc.id, ...doc.data()} as Startup;
  },

  async findPriceHistory(
    startupId: string,
    limit: number
  ): Promise<Array<{
    price: number;
    type: string;
    source: string;
    quantity: number;
    createdAt: string | null;
  }>> {
    const snapshot = await db
      .collection(STARTUPS).doc(startupId)
      .collection(PRICE_HISTORY)
      .orderBy("createdAt", "asc")
      .limitToLast(limit)
      .get();

    return snapshot.docs.map((doc) => {
      const d = doc.data();
      return {
        price: d.price as number,
        type: d.type as string,
        source: d.source as string,
        quantity: d.quantity as number,
        createdAt: d.createdAt?.toDate?.()?.toISOString() ?? null,
      };
    });
  },
};
