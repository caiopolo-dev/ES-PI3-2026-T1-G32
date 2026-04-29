import {getFirestore} from "firebase-admin/firestore";
const db = getFirestore();

/**
 * Registers a new user in Firestore.
 * @param {string} uid User`s uid.
 * @param {string} name User's full name.
 * @param {string} rg User's RG.
 * @param {string} telefone User's phone number.
 * @param {string} email User's email address.
 * @return {Promise<string>} The ID of the created user document.
 */
export async function registerUser(
  uid: string,
  name: string,
  rg: string,
  telefone: string,
  email: string
): Promise<string> {
  const banco = db.collection("users");
  await banco.doc(uid).set({
    name,
    rg,
    telefone,
    email,
  });
  return uid;
}


/**
 * Checks if an RG is already registered in Firestore.
 * @param {string} rg User's RG.
 * @return {Promise<boolean>} True if the RG already exists.
 */
export async function verificarRgExiste(rg: string): Promise<boolean> {
  const snapshot = await db
    .collection("users")
    .where("rg", "==", rg)
    .limit(1)
    .get();

  return !snapshot.empty;
}


/**
 * Checks if an RG is already registered in Firestore.
 * @param {string} email User's email.
 * @return {Promise<boolean>} True if the email already exists.
 */
export async function verificarEmailExiste(email: string): Promise<boolean> {
  const snapshot = await db
    .collection("users")
    .where("email", "==", email)
    .limit(1)
    .get();
  return !snapshot.empty;
}

