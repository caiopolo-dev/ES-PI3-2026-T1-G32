// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Acesso ao Firestore para FAQs de startups

import {FieldValue} from "firebase-admin/firestore";
import {Faq} from "../types";
import {db} from "../../../shared/firebase";
import {STARTUPS, FAQS} from "../../../shared/collections";

const faqsRef = (startupId: string) =>
  db.collection(STARTUPS)
    .doc(startupId)
    .collection(FAQS);

// Converte um documento do Firestore para o tipo `Faq` usado pelo backend.
// Observações:
// - `criadoEm` é armazenado como `serverTimestamp()` e convertido para
//   milissegundos para facilitar ordenação e transporte via JSON.
// - Usamos `?.toMillis?.()` defensivamente caso o campo ainda não tenha sido
//   resolvido pelo servidor.
const docToFaq = (doc: FirebaseFirestore.QueryDocumentSnapshot): Faq => ({
  id: doc.id,
  pergunta: doc.data().pergunta,
  privada: doc.data().privada,
  email: doc.data().email,
  nomeUsuario: doc.data().nomeUsuario,
  criadoEm: doc.data().criadoEm?.toMillis?.() ?? 0,
});

export const faqsRepository = {
  /**
   * Returns the FAQs of a startup visible to the requesting user.
   * Public FAQs are always included. Private FAQs are only included
   * when the user holds tokens of the startup and is the author.
   * @param {string} startupId Startup document ID.
   * @param {boolean} hasTokens Whether the user holds tokens of this startup.
   * @param {string} userEmail Email of the requesting user.
   * @return {Promise<Faq[]>} FAQs sorted by most recent first.
   */
  async findByStartup(
    startupId: string,
    hasTokens: boolean,
    userEmail: string
  ): Promise<Faq[]> {
    const snapshot = await faqsRef(startupId).get();

    // Públicas: sempre visíveis.
    // Privadas: visíveis só para o autor, se ele tiver tokens.
    return snapshot.docs
      .map(docToFaq)
      .filter((faq) => !faq.privada || (hasTokens && faq.email === userEmail))
      .sort((a, b) => (b.criadoEm ?? 0) - (a.criadoEm ?? 0));
  },

  /**
   * Creates a new FAQ entry for a startup.
   * @param {string} startupId Startup document ID.
   * @param {string} pergunta Question text.
   * @param {boolean} privada Whether the question is private (author-only).
   * @param {string} email Author's email address.
   * @param {string} nomeUsuario Author's display name.
   * @return {Promise<void>}
   */
  async create(
    startupId: string,
    pergunta: string,
    privada: boolean,
    email: string,
    nomeUsuario: string
  ): Promise<void> {
    // Insere o documento usando `serverTimestamp()` para que o timestamp seja
    // definido pelo servidor, evitando desvio de relógio do cliente.
    await faqsRef(startupId).add({
      pergunta,
      privada,
      email,
      nomeUsuario,
      criadoEm: FieldValue.serverTimestamp(),
    });
  },
};
