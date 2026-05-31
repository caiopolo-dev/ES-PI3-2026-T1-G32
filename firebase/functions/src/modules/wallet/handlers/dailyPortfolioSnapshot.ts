// Autor: Gustavo Alves de Siqueira Costa
// Data: 28/05/2026
// Descrição: Job diário que salva o snapshot de portfólio de todos os usuários
// com tokens às 23:58 (horário de Brasília). Garante um ponto por dia mesmo
// sem transações do usuário, capturando variações de preço de outros usuários.

import {onSchedule} from "firebase-functions/v2/scheduler";
import {listAllUserIds} from "../../users/repositories/userRepository";
import {updateTodaySnapshot} from "../repositories/portfolioRepository";

// Job agendado que captura um snapshot diário do portfólio de cada usuário
// com tokens às 23:58 (horário de Brasília).
// Observações:
// - Executa em paralelo (`Promise.all`) para throughput; falhas por usuário
//   são logadas mas não interrompem o processamento dos demais.
// - Uso principal: garante um ponto diário no histórico mesmo sem transações
//   do usuário, permitindo análise de variação de preços ao longo do tempo.

export const dailyPortfolioSnapshot = onSchedule(
  {
    schedule: "58 23 * * *",
    timeZone: "America/Sao_Paulo",
  },
  async () => {
    const userIds = await listAllUserIds();

    await Promise.all(
      userIds.map((uid) =>
        updateTodaySnapshot(uid).catch((e) =>
          console.warn(`dailyPortfolioSnapshot falhou para ${uid}:`, e)
        )
      )
    );

    const count = userIds.length;
    console.log(`dailyPortfolioSnapshot: ${count} usuários processados.`);
  }
);
