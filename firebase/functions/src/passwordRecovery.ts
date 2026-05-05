// Rafael Mendes Valente - RA: 25002875

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as nodemailer from "nodemailer";
import {getAuth} from "firebase-admin/auth";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER || process.env.email_user,
    pass: process.env.EMAIL_PASS || process.env.email_pass,
  },
});

export const sendPasswordRecovery = onCall(async (request) => {
  const { email } = request.data;

  if (!email) {
    throw new HttpsError("invalid-argument", "E-mail não informado");
  }

  try {
    const resetLink = await getAuth().generatePasswordResetLink(email);

    await transporter.sendMail({
      from: '"Mescla Invest" <seu_email@gmail.com>',
      to: email,
      subject: "Recuperação de senha",
      text: `
Recuperação de senha

Clique no link abaixo para redefinir sua senha:
${resetLink}

Se você não solicitou, ignore este e-mail.
      `,
    });

  } catch (error) {
    console.error("Erro:", error);
  }

  return {
    message:
      "Se existir uma conta com esse e-mail, você receberá um link de recuperação",
  };
});
