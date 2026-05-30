import {TxType} from "./collections";

// Fração do preço impactada a cada 100% dos tokens negociados.
// Ex: negociar 10% do total → preço muda 5% (0.10 * 0.5).
export const FATOR_IMPACTO = 0.5;

// Operações que aumentam o preço: compra direta, compra no balcão,
// cancelamento de oferta (reverte o impacto da venda).
const OPERACOES_DE_ALTA = new Set([TxType.BUY, TxType.RETURN, TxType.CANCEL_OFFER]);

// Calcula o novo preço do token com base no tipo da operação.
// Recebe o TX_TYPE da transação e determina internamente se o preço sobe ou cai.
export function calcularNovoPreco(
  precoAtual: number,
  quantity: number,
  totalTokens: number,
  tipoOperacao: TxType
): number {
  const impacto = (quantity / totalTokens) * FATOR_IMPACTO;
  const novoPreco = OPERACOES_DE_ALTA.has(tipoOperacao)
    ? Math.round(precoAtual * (1 + impacto))
    : Math.round(precoAtual * (1 - impacto));
  return Math.max(1, novoPreco);
}
