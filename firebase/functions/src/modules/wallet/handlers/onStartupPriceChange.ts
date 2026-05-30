// Autor: Gustavo Alves de Siqueira Costa
// Data: 30/05/2026
// Descrição: Trigger que atualiza todos os snapshots de portfólio
// quando o preço de uma startup muda — desacopla o cálculo de portfólio
// das transações e garante atualização em tempo real para todos os usuários.

import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {updateAllSnapshots} from "../repositories/portfolioRepository";

export const onStartupPriceChange = onDocumentUpdated(
  "startups/{startupId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;
    if (before.precoToken === after.precoToken) return;

    await updateAllSnapshots();
  }
);
