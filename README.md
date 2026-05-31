# MesclaInvest

> Plataforma mobile de simulação de investimentos em startups via tokenização — Projeto Integrador 3 · PUC-Campinas · 2026

---

## Sobre o Projeto

O **MesclaInvest** é um aplicativo móvel que simula um ambiente de investimento em startups vinculadas ao ecossistema **Mescla** da PUC-Campinas. A plataforma permite que usuários explorem startups, adquiram tokens representativos de participação e acompanhem seu portfólio em tempo real.

> ⚠️ Todas as operações, saldos e tokens são **simulados**. Nenhuma operação possui valor financeiro real ou integração com sistemas bancários.

---

## Funcionalidades

- Autenticação com suporte a **2FA via TOTP** (Google Authenticator, Authy etc.)
- Catálogo de startups com filtros por estágio (Nova, Em Operação, Em Expansão) e busca textual
- **Balcão de negociações**: mercado secundário com compra e venda de tokens entre usuários
- **Carteira do usuário**: saldo, histórico de transações e portfólio de tokens com preço médio
- **Gráfico de portfólio**: histórico de valorização persistido com snapshots diários, chip de retorno total e filtros 7D / 1M / 6M / YTD
- **Gráfico de preço da startup**: histórico de transações com filtros 1D / 7D / 1M / 6M / YTD
- **Detalhe de startup**: histórico de preço com gráfico interativo, vídeo de apresentação, PDF de resumo executivo e FAQ pública/privada
- Perfil do usuário com gerenciamento de 2FA
- Pull-to-refresh em todas as telas com dados dinâmicos

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Frontend Mobile | Flutter / Dart |
| Backend (Cloud Functions) | Node.js 24 + TypeScript |
| Banco de Dados | Firebase Firestore |
| Autenticação | Firebase Authentication |
| Armazenamento de mídia | Firebase Storage |
| Infraestrutura | Firebase (Google Cloud) |

---

## Estrutura do Projeto

```
ES-PI3-2026-T1-G32/
├── frontend/
│   └── lib/src/
│       ├── pages/
│       │   ├── public/             # Telas sem autenticação
│       │   │   ├── initial_page.dart
│       │   │   └── auth/           # Login, cadastro, recuperação, 2FA
│       │   └── private/            # Telas pós-login (requerem auth)
│       │       ├── home/           # Resumo financeiro + gráfico de portfólio
│       │       ├── catalog/        # Catálogo de startups
│       │       ├── balcao/         # Mercado secundário de tokens
│       │       ├── wallet/         # Carteira e histórico de transações
│       │       ├── startup_detail/ # Detalhe de startup com gráfico e FAQ
│       │       ├── buy_steps/      # Fluxo de compra e venda de tokens
│       │       └── profile/        # Perfil do usuário e 2FA
│       ├── services/               # Comunicação com Cloud Functions e Storage
│       ├── widgets/
│       │   ├── ui_primitives/      # Botões, chips, campo de busca, gráficos
│       │   ├── finance/            # Componentes financeiros (saldo, depósito)
│       │   └── layout/             # Shell de navegação (MainScaffold)
│       ├── theme/                  # Paleta de cores (AppColors)
│       └── utils/                  # CurrencyFormatter
│
└── firebase/
    ├── functions/src/
    │   ├── shared/
    │   │   ├── collections.ts      # Fonte única de verdade para nomes de coleções e tipos de transação
    │   │   ├── firebase.ts         # Instância compartilhada do Firestore
    │   │   ├── validation.ts       # requireAuth
    │   │   └── tokenPricing.ts     # FATOR_IMPACTO para cálculo de preço
    │   ├── modules/
    │   │   ├── users/              # Cadastro, login, verificação de duplicatas
    │   │   ├── startups/           # Listagem, detalhe, histórico de preço, FAQ
    │   │   ├── tokenOffers/        # Compra direta, balcão (compra/venda/cancelamento)
    │   │   └── wallet/             # Carteira, transações, tokens, portfólio histórico
    │   └── index.ts                # Exporta todas as 20 Cloud Functions
    ├── firestore.rules
    └── firestore.indexes.json
```

---

## Arquitetura das Cloud Functions

As funções seguem uma arquitetura em camadas por módulo:

```
shared/
  collections.ts  → constantes de coleções; enums TxType e TxSource (tipos e origens de transação)
  firebase.ts     → instância db compartilhada
  validation.ts   → requireAuth (type predicate para TypeScript)
  tokenPricing.ts → FATOR_IMPACTO + calcularNovoPreco (lógica de precificação centralizada)

modules/<dominio>/
  handlers/       → recebem a requisição, validam auth e entrada, delegam
  repositories/   → única camada que acessa o Firestore (com JSDoc completo)
```

**Regras arquiteturais:**
- Nenhum handler acessa o Firestore diretamente — toda leitura e escrita passa pelos repositories
- Nenhum repository usa strings literais para nomes de coleções — todas passam por `collections.ts`
- Toda operação que modifica múltiplas coleções usa `runTransaction` para garantir atomicidade
- UIDs de usuário sempre vêm de `request.auth.uid` — nunca do payload do cliente

### Cloud Functions disponíveis

| Módulo | Função | Tipo |
|--------|--------|------|
| users | `createUser`, `getUserData`, `checkUserExists` | onCall |
| startups | `getStartups`, `getStartupById`, `getPriceHistory`, `createFaq`, `getFaqs` | onCall |
| tokenOffers | `buyStartupToken`, `buyOffer`, `createSellOffer`, `cancelOffer`, `listOffers`, `listMyOffers` | onCall |
| wallet | `getWalletInfo`, `getTransactionHistory`, `getUserTokens`, `addBalance`, `getPortfolioHistory` | onCall |
| wallet | `dailyPortfolioSnapshot` | onSchedule (23:58 BRT) |
| wallet | `onStartupPriceChange` | onDocumentUpdated (atualiza snapshots de portfólio em tempo real) |

---

## Modelo de Dados (Firestore)

```
users/{uid}
  ├── wallet/saldo              → saldo em centavos
  ├── tokens/{startupId}        → quantidade, precoMedio, valorAtual
  └── portfolioHistory/{date}   → returnPercent, investedCents, valueCents

startups/{id}
  ├── priceHistory/{docId}      → price, type, source, quantity, createdAt
  └── faqs/{docId}              → pergunta, privada, email, nomeUsuario

token_offers/{id}               → seller, startup, amount, valorUnitarioCentavos, status
transactions/{id}               → type, buyerId, sellerId, startupId, quantity, totalCents
```

---

## Lógica de Precificação de Tokens

O preço de cada token varia dinamicamente a cada transação com base em oferta e demanda simuladas. O fator de impacto está definido em `tokenPricing.ts` como `FATOR_IMPACTO = 0.5`.

| Evento | Efeito no preço |
|--------|----------------|
| Compra direta / Compra de oferta | Preço sobe proporcionalmente à quantidade comprada em relação ao total de tokens |
| Criação de oferta de venda | Preço cai (aumento de oferta no mercado) |
| Cancelamento de oferta | Preço volta ao nível anterior (oferta retirada do mercado) |

Fórmula: `novoPreco = precoAtual × (1 ± quantidade/totalTokens × FATOR_IMPACTO)`

O preço mínimo é protegido por `Math.max(1, novoPreco)` — nunca cai abaixo de 1 centavo.

---

## Fluxo de Registro

O cadastro é realizado em duas etapas atômicas:

1. **Firebase Auth** — cria a conta com e-mail e senha e envia o e-mail de verificação
2. **Cloud Function `createUser`** — salva os dados complementares (nome, RG, telefone) no Firestore e inicializa a carteira com saldo zero

Se a Cloud Function falhar após o Auth ser criado, a conta do Auth é deletada automaticamente para evitar usuários órfãos. O login só é liberado após a confirmação do e-mail.

---

## Preço Médio Ponderado

Cada token na carteira do usuário possui um **preço médio de aquisição** calculado automaticamente a cada compra usando média ponderada:

```
novoPrecoMedio = (qtdAnterior × precoMedioAnterior + qtdComprada × precoAtual) / novaQtdTotal
```

Isso permite ao usuário comparar o custo médio de aquisição (`precoMedio`) com o valor atual do token (`valorAtual`) e visualizar o retorno da posição diretamente na carteira.

---

## Histórico de Portfólio

O gráfico de portfólio usa snapshots diários persistidos em `users/{uid}/portfolioHistory/{YYYY-MM-DD}`. Cada ponto é criado ou atualizado:

- **Em tempo real**: após cada compra, venda ou cancelamento de oferta
- **Diariamente**: o job `dailyPortfolioSnapshot` roda às 23:58 BRT e salva um ponto para todos os usuários com tokens, capturando variações de preço mesmo sem transações

---

## Testes

O projeto inclui testes unitários para as regras de negócio do fluxo de compra de tokens.

```bash
cd frontend
flutter test
```

Os testes cobrem:
- Cálculo do total da compra em centavos (`preço × quantidade`)
- Cálculo do saldo restante após compra
- Validação de quantidade (zero e negativa são rejeitadas)
- Validação de saldo suficiente para a compra

---

## Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.x
- [Node.js](https://nodejs.org/) 24.x
- [Firebase CLI](https://firebase.google.com/docs/cli) instalado e autenticado
- Acesso ao projeto Firebase `es-pi3-2026-t1-g32`

---

## Configuração do Ambiente

O arquivo `frontend/lib/firebase_options.dart` contém as chaves do projeto Firebase e é gerado automaticamente pelo [FlutterFire CLI](https://firebase.flutter.dev/docs/cli). Se precisar regenerar:

```bash
dart pub global activate flutterfire_cli
cd frontend
flutterfire configure --project=es-pi3-2026-t1-g32
```

Os arquivos `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) também são necessários e devem estar nos diretórios padrão do Flutter. Solicite ao time caso não estejam no repositório.

---

## Como Executar

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### Backend (verificar e buildar localmente)

```bash
cd firebase/functions
npm install
npm run lint
npm run build
```

### Deploy das Cloud Functions

```bash
cd firebase
firebase deploy --only functions
```

---

## Integrantes

| Nome | RA |
|---|---|
| Caio Ferreira Polo | 25002823 |
| Giovanni Bozelli | 25006837 |
| Gustavo Alves de Siqueira Costa | 25001650 |
| Henrique Leite de Camargo | 25005997 |
| Rafael Mendes Valente | 25002875 |

---

*Projeto Integrador 3 — Engenharia de Software — PUC-Campinas · 2026 · Grupo ES-PI3-2026-T1-G32*
