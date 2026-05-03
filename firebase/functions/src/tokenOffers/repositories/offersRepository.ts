// Caio Ferreir Polo - 25002823
import {getFirestore} from "firebase-admin/firestore";
const db = getFirestore();

/**
 * Lists all token offers from Firestore.
 * @return {Promise<Array<object>>} List of token offers.
 */
export async function listAllOffers() {
  const snapshot = await db.collection("token_offers").get();
  const offers = snapshot.docs.map((doc) => {
    const data = doc.data();

    return {
      offerId: doc.id,
      startupId: data.startupId,
      sellerId: data.sellerId,
      amount: data.amount,
      valorUnitarioCentavos: data.valorUnitarioCentavos,
    };
  });
  return offers;
}
