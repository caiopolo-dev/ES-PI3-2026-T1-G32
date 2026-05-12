import {onCall, HttpsError} from "firebase-functions/v2/https";
import {requireAuth} from "../../../shared/validation";

export const buyToken = onCall(async (request) => {
  requireAuth(request.auth);
});
