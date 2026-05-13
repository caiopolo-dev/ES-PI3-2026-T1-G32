// Autor: Gustavo Alves de Siqueira Costa
// Data: 23/04/2026
// Descrição: Instância compartilhada do Firestore

import {getFirestore} from "firebase-admin/firestore";

export const db = getFirestore();
