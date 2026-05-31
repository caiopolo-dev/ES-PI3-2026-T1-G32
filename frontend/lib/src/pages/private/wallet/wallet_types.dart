// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Tipos e enums da carteira

enum TokenSort { alfa, precoAsc, precoDesc }

enum TxFilter { todos, deposito, compra, venda, cancelamento }

// Observações:
// - `TokenSort` define a ordenação dos tokens na lista (alfabética ou por preço).
// - `TxFilter` é usado para filtrar o histórico de transações por tipo.
