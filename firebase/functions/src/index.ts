import * as admin from "firebase-admin";
admin.initializeApp();

// Entry point principal
// Exportar funcionalidades dos domínios: users, startups, exchange
export * from "./users";
export * from "./startups";
