// Caio Ferreira Polo 25002823

import {onRequest} from "firebase-functions/https";
import {Request, Response} from "express";
import {verificarRgExiste, buscarUsuarioPorRG} from
  "../repositories/userRepository";

/**
 * Faz login de um usuário usando RG e senha.
 * Retorna dados do usuário se válido, ou erro específico.
 */
export const loginUser = onRequest(
  async (request: Request, response: Response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Método não permitido"});
      return;
    }

    try {
      const {rg, senha} = request.body;

      if (!rg || !senha) {
        response.status(400).json({
          error: "Dados incompletos",
          message: "RG e senha são obrigatórios",
        });
        return;
      }

      // Verifica se RG existe
      const rgExiste = await verificarRgExiste(rg);
      if (!rgExiste) {
        response.status(404).json({
          error: "RG não cadastrado",
          message: "Esse RG não está registrado no sistema",
        });
        return;
      }

      // Busca usuário por RG
      const usuario = await buscarUsuarioPorRG(rg);

      if (!usuario) {
        response.status(404).json({
          error: "Usuário não encontrado",
          message: "Erro ao buscar usuário",
        });
        return;
      }

      // Valida senha
      if (usuario.senha !== senha) {
        response.status(401).json({
          error: "Senha incorreta",
          message: "A senha informada está incorreta",
        });
        return;
      }

      // Login bem-sucedido
      response.status(200).json({
        success: true,
        message: "Login realizado com sucesso",
        usuario: {
          uid: usuario.uid,
          rg: usuario.RG,
          email: usuario.email,
          nome_completo: usuario.nome_completo,
          saldo_carteira: usuario.saldo_carteira,
        },
      });
    } catch (error) {
      console.error("Erro ao fazer login:", error);
      response.status(500).json({
        error: "Erro interno do servidor",
        message: "Ocorreu um erro ao processar seu login",
      });
    }
  }
);
