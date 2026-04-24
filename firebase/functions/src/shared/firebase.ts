// Autor: Gustavo Alves de Siqueira Costa
// Data: 23/04/2026
// Descrição: Configuração do Firestore compartilhada

// shared/firebase.ts
import * as admin from "firebase-admin";

export const db = admin.firestore();
