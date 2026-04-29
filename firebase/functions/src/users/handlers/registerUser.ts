import {onCall, HttpsError} from "firebase-functions/v2/https";
import {registerUser, verificarRgExiste,
  verificarEmailExiste} from "../repositories/userRepository";


export const createUser = onCall(async (request)=>{
  const {name, rg, telefone, email} = request.data;


  if (!name || !rg || !telefone || !email) {
    throw new HttpsError(
      "invalid-argument",
      "Informações vazias ou invalidas"
    );
  }

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado");
  }

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


  const uid = request.auth.uid;
  const result = await registerUser(uid, name, rg, telefone, email);

  return result;
});
