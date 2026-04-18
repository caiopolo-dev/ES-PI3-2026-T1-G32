// Caio Ferreira Polo - 25002823

import * as admin from "firebase-admin";

const db = admin.firestore();
const usersCollection = db.collection("users");

/**
 * Verifica se um RG já existe na base de dados.
 * @param {string} rg - O RG a verificar
 * @return {Promise<boolean>} True se existe, false caso contrário
 */
export async function verificarRgExiste(rg: string): Promise<boolean> {
  try {
    const query = await usersCollection.where("RG", "==", rg).limit(1).get();
    return !query.empty;
  } catch (error) {
    console.error("Erro ao verificar RG:", error);
    throw error;
  }
}

/**
 * Verifica se um email já existe na base de dados.
 * @param {string} email - O email a verificar
 * @return {Promise<boolean>} True se existe, false caso contrário
 */
export async function verificarEmailExiste(email: string): Promise<boolean> {
  try {
    const query = await usersCollection
      .where("email", "==", email)
      .limit(1)
      .get();
    return !query.empty;
  } catch (error) {
    console.error("Erro ao verificar email:", error);
    throw error;
  }
}

/**
 * Cria um novo usuário na base de dados.
 * @param {Object} userData - Dados do usuário a criar
 * @return {Promise<string>} ID do documento criado
 */
export async function criarUsuario(userData: {
  RG: string;
  email: string;
  numero: string;
  nome: string;
  senha: string;
}): Promise<string> {
  try {
    const novoUsuario = {
      RG: userData.RG,
      email: userData.email,
      telefone: userData.numero,
      nome_completo: userData.nome,
      senha: userData.senha,
      saldo_carteira: 0,
      dois_fatores: false,
      data_criacao: admin.firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await usersCollection.add(novoUsuario);
    return docRef.id;
  } catch (error) {
    console.error("Erro ao criar usuário:", error);
    throw error;
  }
}

