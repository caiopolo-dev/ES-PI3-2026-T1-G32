// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Tipos e enums da tela de detalhes de startup

enum PriceHistoryPeriod { oneDay, sevenDays, oneMonth, sixMonths, oneYear, all }

enum FaqFilter { todas, publicas, privadas }

enum StartupDetailSection { chart, offers }
// Observações:
// - `PriceHistoryPeriod` define os intervalos usados para filtrar o histórico
//   de preços exibido no gráfico (1D, 7D, 1M, 6M, 1Y, Tudo).
// - `FaqFilter` controla quais FAQs mostrar: todas, apenas públicas ou apenas
//   privadas (as privadas geralmente são visíveis apenas para investidores
//   que possuem tokens).
// - `StartupDetailSection` representa as abas internas da tela de detalhe
//   (gráfico de variação ou ofertas do balcão).
