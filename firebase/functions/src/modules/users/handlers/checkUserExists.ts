// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Verifica se o email existe no Auth
// antes de enviar recuperação de senha

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getAuth} from "firebase-admin/auth";

// Handler que verifica se um e-mail está cadastrado no Firebase Auth.
// Propósito: permitir validação antes de iniciar fluxo de recuperação
// de senha sem expor diretamente mensagens internas do Auth.
// Comportamento: lança `HttpsError` com códigos apropriados para o cliente.

export const checkUserExists = onCall(async (request) => {
  const {email} = request.data;

  if (!email) {
    throw new HttpsError("invalid-argument", "E-mail não informado");
  }

  // Verifica antes de chamar sendPasswordResetEmail para evitar revelar
  // ao usuário se um email existe ou não via mensagem de erro do Firebase.
  try {
    await getAuth().getUserByEmail(email);
  } catch (e: unknown) {
    const code = (e as {code?: string}).code;
    if (code === "auth/user-not-found") {
      throw new HttpsError(
        "not-found",
        "Nenhuma conta encontrada com este e-mail"
      );
    }
    throw new HttpsError("internal", "Erro ao verificar usuário");
  }

  return {success: true};
});
