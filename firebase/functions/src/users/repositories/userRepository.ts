// Caio Ferreira Polo 25002823

import {db} from "../../shared/firebase";

/**
 * Registers a new user in Firestore.
 * @param {string} uid User`s uid.
 * @param {string} name User's full name.
 * @param {string} rg User's RG.
 * @param {string} telefone User's phone number.
 * @param {string} email User's email address.
 * @param {number} saldo User's starter money amount in centavos.
 * @return {Promise<string>} The ID of the created user document.
 */
export async function registerUser(
  uid: string,
  name: string,
  rg: string,
  telefone: string,
  email: string,
  saldo: number
): Promise<string> {
  const banco = db.collection("users");
  const userRef = banco.doc(uid);
  const walletRef = userRef.collection("wallet").doc("saldo");
  const batch = db.batch();
  batch.set(userRef, {
    name,
    rg,
    telefone,
    email,
  });
  batch.set(walletRef, {
    saldo,
  });
  await batch.commit();
  return uid;
}


/**
 * Returns a user document by UID.
 * @param {string} uid User ID.
 * @return {Promise<FirebaseFirestore.DocumentSnapshot>} User document.
 */
export async function getUserById(uid: string) {
  return db.collection("users").doc(uid).get();
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

