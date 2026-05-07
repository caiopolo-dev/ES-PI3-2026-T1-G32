import {initializeApp} from "firebase-admin/app";

initializeApp();

export {createUser} from "./users/handlers/registerUser";
export {getUserData} from "./users/handlers/getUserData";
export {getStartups} from "./startups/handlers/getStartups";
export {getStartupById} from "./startups/handlers/getStartupById";
export {createFaq} from "./startups/handlers/createFaq";
export {getFaqs} from "./startups/handlers/getFaqs";
export {listOffers} from "./tokenOffers/handlers/listTokenOffers";
export {checkUserExists} from "./users/handlers/checkUserExists";
export {buyOffer} from "./tokenOffers/handlers/buyOffer";
