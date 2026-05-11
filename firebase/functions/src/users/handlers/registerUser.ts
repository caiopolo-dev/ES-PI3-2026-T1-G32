// Autor: Caio Ferreira Polo
// Descrição: Handler para cadastro de um novo usuário no Firestore

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {registerUser, verificarRgExiste,
  verificarEmailExiste} from "../repositories/userRepository";


export const createUser = onCall(async (request)=>{
  const {name, rg, telefone, email} = request.data;
  // Novos usuários começam sem saldo; depósitos são feitos fora do sistema.
  const saldoCentavos = 0;

  // Validação dos dados antes de verificar autenticação para retornar erro mais descritivo.
  if (!name || !rg || !telefone || !email) {
    throw new HttpsError(
      "invalid-argument",
      "Informações vazias ou invalidas"
    );
  }

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

  // Verifica duplicidade de RG e e-mail no Firestore antes de criar o documento.
  const verifyRg = await verificarRgExiste(rg);

  if (verifyRg) {
    throw new HttpsError(
      "already-exists",
      "RG já cadastrado"
    );
  }

  const verifyEmail = await verificarEmailExiste(email);

  if (verifyEmail) {
    throw new HttpsError(
      "already-exists",
      "e-mail já cadastrado"
    );
  }

  // uid vem do Firebase Auth — garante que o documento do Firestore
  // sempre usa o mesmo ID que a conta de autenticação.
  const uid = request.auth.uid;
  const result = await registerUser(
    uid, name, rg, telefone, email, saldoCentavos);

  return result;
});
