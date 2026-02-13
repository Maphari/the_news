import { Request, Response } from "express";
import axios from "axios";

const OPENAI_API_KEY = process.env.OPENAI_API_KEY || "";
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";
const OPENAI_COST_PER_ITEM_USD = Number(process.env.OPENAI_COST_PER_ITEM_USD || "0.0003");
const PROXY_COST_PER_ITEM_USD = Number(process.env.PROXY_COST_PER_ITEM_USD || "0.00025");
const AI_CACHE_TTL_DAYS = Number(process.env.AI_CACHE_TTL_DAYS || "7");

export const healthCheck = (_req: Request, res: Response) => {
  const providers: string[] = [];
  if (OPENAI_API_KEY) providers.push("openai");

  if (providers.length === 0) {
    return res.status(503).json({
      success: false,
      message: "No AI providers configured on server",
      providers,
    });
  }

  return res.status(200).json({
    success: true,
    providers,
    defaultProvider: providers[0],
    cacheTtlDays: AI_CACHE_TTL_DAYS,
  });
};

export const getMetadata = (_req: Request, res: Response) => {
  const providers: string[] = [];
  if (OPENAI_API_KEY) providers.push("openai");

  return res.status(200).json({
    success: true,
    providers,
    defaultProvider: providers[0] || null,
    cacheTtlDays: AI_CACHE_TTL_DAYS,
    pricing: {
      proxy: {
        perDigestItemUsd: PROXY_COST_PER_ITEM_USD,
      },
      openai: {
        perDigestItemUsd: OPENAI_COST_PER_ITEM_USD,
      },
    },
  });
};

export const generateText = async (req: Request, res: Response) => {
  try {
    const { prompt, maxTokens = 200, provider } = req.body as {
      prompt?: string;
      maxTokens?: number;
      provider?: string;
    };

    if (!prompt || typeof prompt !== "string") {
      return res.status(400).json({
        success: false,
        message: "Prompt is required",
      });
    }

    const chosenProvider = provider || "openai";

    if (chosenProvider !== "openai") {
      return res.status(400).json({
        success: false,
        message: `Provider not supported: ${chosenProvider}`,
      });
    }

    if (!OPENAI_API_KEY) {
      return res.status(503).json({
        success: false,
        message: "OpenAI API key not configured on server",
      });
    }

    const response = await axios.post(
      "https://api.openai.com/v1/chat/completions",
      {
        model: OPENAI_MODEL,
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: prompt },
        ],
        max_tokens: Math.min(Math.max(Number(maxTokens) || 200, 50), 800),
      },
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY}`,
        },
        timeout: 20000,
      },
    );

    type OpenAIChatResponse = {
      choices?: Array<{ message?: { content?: string | null } }>;
    };
    const typedData = response.data as OpenAIChatResponse;
    const result = typedData.choices?.[0]?.message?.content?.toString() || "";

    return res.status(200).json({
      success: true,
      provider: "openai",
      model: OPENAI_MODEL,
      result,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown error";
    return res.status(500).json({
      success: false,
      message: "AI proxy failed",
      error: message,
    });
  }
};
