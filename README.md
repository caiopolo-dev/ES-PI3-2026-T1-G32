# MesclaInvest

> Plataforma mobile de simulação de investimentos em startups via tokenização — Projeto Integrador 3 · PUC-Campinas · 2026

---

## Sobre o Projeto

O **MesclaInvest** é um aplicativo móvel que simula um ambiente de investimento em startups vinculadas ao ecossistema **Mescla** da PUC-Campinas. A plataforma permite que usuários explorem startups, adquiram tokens representativos de participação e acompanhem seu portfólio em tempo real.

> ⚠️ Todas as operações, saldos e tokens são **simulados**. Nenhuma operação possui valor financeiro real ou integração com sistemas bancários.

---

## Funcionalidades

- Autenticação de usuários com suporte a **autenticação de dois fatores (2FA/TOTP)**
- Catálogo de startups com filtros por estágio (Nova, Em Operação, Em Expansão)
- **Balcão de negociações**: listagem e compra de ofertas de tokens disponíveis
- **Carteira do usuário**: saldo, histórico de transações e portfólio de tokens
- FAQ por startup (pública e privada)
- Perfil do usuário
- **Venda de tokens**: criação de ofertas de venda no balcão a partir do portfólio do usuário
- **Acompanhamento de valorização**: visualização da variação percentual do valor dos tokens adquiridos em relação ao preço médio de compra

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Frontend Mobile | Flutter / Dart |
| Backend (Cloud Functions) | Node.js 24 + TypeScript |
| Banco de Dados | Firebase Firestore |
| Autenticação | Firebase Authentication |
| Infraestrutura | Firebase (Google Cloud) |

---

## Estrutura do Projeto

```
ES-PI3-2026-T1-G32/
├── frontend/               # Aplicativo Flutter
│   └── lib/src/
│       ├── pages/          # Telas da aplicação
│       └── services/       # Camada de comunicação com Cloud Functions
│
└── firebase/
    ├── functions/src/      # Cloud Functions (TypeScript)
    │   ├── shared/         # Instâncias compartilhadas
    │   ├── users/          # Funções de usuário
    │   ├── startups/       # Funções de startups e FAQs
    │   ├── tokenOffers/    # Funções de ofertas e compra de tokens
    │   └── wallet/         # Funções de carteira e portfólio
    ├── firestore.rules     # Regras de segurança do Firestore
    └── firestore.indexes.json
```

---

## Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.x
- [Node.js](https://nodejs.org/) 24.x
- [Firebase CLI](https://firebase.google.com/docs/cli) instalado e autenticado
- Acesso ao projeto Firebase `es-pi3-2026-t1-g32`

---

## Como Executar

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

### Backend (Cloud Functions)

```bash
cd firebase/functions
npm install
npm run build
```

### Deploy das Cloud Functions

```bash
cd firebase
firebase deploy --only functions
```

---

## Arquitetura das Cloud Functions

As funções seguem uma arquitetura em camadas por módulo:

```
handlers/     → recebem a requisição, validam auth e delegam
repositories/ → única camada que acessa o Firestore
shared/       → instância compartilhada do db
```

Nenhum handler acessa o Firestore diretamente — toda leitura e escrita passa pelos repositories.

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
