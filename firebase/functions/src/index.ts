import {initializeApp} from "firebase-admin/app";

initializeApp();
export {createUser} from "./users/handlers/registerUser";
export {getStartups} from "./startups/handlers/getStartups";
export {getStartupById} from "./startups/handlers/getStartupById";
