import axios from "axios";
import { env } from "../config/env.js";

const client = axios.create({
  baseURL: env.aiServiceUrl,
  timeout: 15_000,
});

export const ai = {
  /** Analyze post text for toxicity / misinformation signals. */
  async analyzeText({ text, language = "en" }) {
    const { data } = await client.post("/v1/analyze", {
      text,
      language,
    });
    return data;
  },

  /** Look up known claim reviews via the AI service's fact-check proxy. */
  async factCheck({ query }) {
    const { data } = await client.get("/v1/factcheck", {
      params: { query },
    });
    return data;
  },
};
