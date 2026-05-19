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

const docToFaq = (doc: FirebaseFirestore.QueryDocumentSnapshot): Faq => ({
  id: doc.id,
  pergunta: doc.data().pergunta,
  privada: doc.data().privada,
  email: doc.data().email,
  nomeUsuario: doc.data().nomeUsuario,
  criadoEm: doc.data().criadoEm?.toMillis?.() ?? 0,
});

export const faqsRepository = {
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

  async create(
    startupId: string,
    pergunta: string,
    privada: boolean,
    email: string,
    nomeUsuario: string
  ): Promise<void> {
    await faqsRef(startupId).add({
      pergunta,
      privada,
      email,
      nomeUsuario,
      criadoEm: FieldValue.serverTimestamp(),
    });
  },
};
