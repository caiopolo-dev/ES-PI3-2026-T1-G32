// Autor: Gustavo Alves de Siqueira Costa
// Data: 23/04/2026
// Descrição: Handlers das requisições HTTP de startups

import * as functions from "firebase-functions";
import {startupRepository} from "../repositories/startupRepository";
import {EstagioStartup} from "../types";

// GET /startups
// Retorna todas as startups, com filtro opcional por estágio
// Exemplo: GET /startups?estagio=nova
export const getStartups = functions.https.onRequest(async (req, res) => {
  try {
    const estagio = req.query.estagio as EstagioStartup | undefined;
    const startups = await startupRepository.findAll(estagio);

    res.status(200).json({
      success: true,
      data: startups,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Erro ao buscar startups",
    });
  }
});

// GET /startups/:id
// Retorna os detalhes de uma startup específica pelo ID
// Exemplo: GET /startups/ecotrack
export const getStartupById = functions.https.onRequest(async (req, res) => {
  try {
    const id = req.path.split("/")[1];
    const startup = await startupRepository.findById(id);

    if (!startup) {
      res.status(404).json({
        success: false,
        message: "Startup não encontrada",
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: startup,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Erro ao buscar startup",
    });
  }
});
