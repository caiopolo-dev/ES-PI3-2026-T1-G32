// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Acesso ao Firestore para FAQs de startups

import {FieldValue} from "firebase-admin/firestore";
import {Faq} from "../types";
import {db} from "../../shared/firebase";
const STARTUPS_COLLECTION = "startups";
const FAQS_SUBCOLLECTION = "faqs";

const faqsRef = (startupId: string) =>
  db.collection(STARTUPS_COLLECTION)
    .doc(startupId)
    .collection(FAQS_SUBCOLLECTION);

const docToFaq = (doc: FirebaseFirestore.QueryDocumentSnapshot): Faq => ({
  id: doc.id,
  pergunta: doc.data().pergunta,
  privada: doc.data().privada,
  email: doc.data().email,
  nomeUsuario: doc.data().nomeUsuario,
  criadoEm: doc.data().criadoEm?.toMillis?.() ?? 0,
});

export const faqsRepository = {
  async findByStartup(startupId: string, userEmail: string): Promise<Faq[]> {
    const snapshot = await faqsRef(startupId).get();

    // FAQs privadas só são visíveis para o próprio autor (comparado pelo email do token JWT).
    return snapshot.docs
      .map(docToFaq)
      .filter((faq) => !faq.privada || faq.email === userEmail)
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
