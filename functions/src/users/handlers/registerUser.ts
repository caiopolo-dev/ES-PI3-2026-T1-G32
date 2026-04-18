// caio ferreira polo 25002823

import * as functions from "firebase-functions";
import {Request, Response} from "express";
import {UserInput} from "../types";
import {
  verificarRgExiste,
  verificarEmailExiste,
  criarUsuario,
} from "../repositories/userRepository";

export const registerUser = functions.https.onRequest(
  async (request: Request, response: Response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Método não permitido"});
      return;
    }

    try {
      const data: UserInput = request.body;

      const rgExiste = await verificarRgExiste(data.RG);
      if (rgExiste) {
        response.status(409).json({
          error: "RG já cadastrado",
          message: "Esse RG já está registrado no sistema",
        });
        return;
      }

      const emailExiste = await verificarEmailExiste(data.email);
      if (emailExiste) {
        response.status(409).json({
          error: "Email já cadastrado",
          message: "Esse email já está registrado no sistema",
        });
        return;
      }

      const userId = await criarUsuario(data);

      response.status(200).json({
        success: true,
        message: "Usuário registrado com sucesso",
        userId: userId,
      });
    } catch (error) {
      console.error("Erro ao registrar usuário:", error);
      response.status(500).json({
        error: "Erro interno do servidor",
        message: "Ocorreu um erro ao processar seu registro",
      });
    }
  }
);

