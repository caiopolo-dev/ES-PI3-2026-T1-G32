// Autor: Caio Ferreira Polo
// Descrição: Handler para cadastro de um novo usuário no Firestore

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {registerUser, verificarRgExiste,
  verificarEmailExiste} from "../repositories/userRepository";
import {requireAuth} from "../../../shared/validation";


// Handler para criação de documento de usuário no Firestore.
// Pontos chave:
// - Requer autenticação; o `uid` do Auth é usado como ID do documento.
// - Verifica duplicidade de RG e e-mail antes de criar.
// - Inicia saldo em centavos (`saldoCentavos = 0`); depósitos são externos.


export const createUser = onCall(async (request)=>{
  requireAuth(request.auth);

  const {name, rg, telefone, email} = request.data;
  // Novos usuários começam sem saldo; depósitos são feitos fora do sistema.
  const saldoCentavos = 0;

  if (!name || !rg || !telefone || !email) {
    throw new HttpsError(
      "invalid-argument",
      "Informações vazias ou invalidas"
    );
  }

  // Verifica duplicidade de RG e e-mail antes de criar o documento.
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
