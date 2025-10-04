import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { aiBot } from "./ai-bot";
import { gameLoop } from "./game-loop";
import { cardImageLoader } from "./card-loader";
import { z } from "zod";

const createUserSchema = z.object({
  username: z.string().min(2),
  displayName: z.string().min(1),
});

export async function registerRoutes(app: Express): Promise<Server> {
  app.get("/api/health", (_req, res) => {
    res.json({ ok: true, service: "KudurruKings", ts: Date.now() });
  });

  app.get("/api/users/:id", async (req, res) => {
    const user = await storage.getUser(req.params.id);
    if (!user) return res.status(404).json({ error: "Not found" });
    res.json(user);
  });

  app.get("/api/users", async (req, res) => {
    const { username } = req.query as { username?: string };
    if (username) {
      const user = await storage.getUserByUsername(username);
      if (!user) return res.status(404).json({ error: "Not found" });
      return res.json(user);
    }
    res.json({ users: storage.listUsers?.() ?? [] });
  });

  app.post("/api/users", async (req, res) => {
    const parsed = createUserSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.flatten() });
    }
    const created = await storage.createUser(parsed.data);
    res.status(201).json(created);
  });

  app.get("/api/game", (_req, res) => {
    res.json(storage.getGameState());
  });

  app.get("/api/game/debug", (_req, res) => {
    const state = storage.getGameState();
    const activePlayer = state.players.find(p => p.isActive);
    res.json({
      phase: state.phase,
      activePlayerId: activePlayer?.id,
      activePlayerName: activePlayer?.name,
      activePlayerHand: activePlayer?.hand.length,
      activePlayerBattlefield: activePlayer?.battlefield.length,
      allPlayers: state.players.map(p => ({
        id: p.id,
        name: p.name,
        isActive: p.isActive,
        handSize: p.hand.length,
        battlefieldSize: p.battlefield.length,
        resources: p.resources,
        marks: p.marks
      }))
    });
  });

  app.post("/api/game/play", (req, res) => {
    const { cardId } = req.body || {};
    res.json(storage.playCard(cardId));
  });

  app.post("/api/game/end-phase", (_req, res) => {
    res.json(storage.endPhase());
  });

  app.post("/api/game/attack", (req, res) => {
    const { attackerId, defenderIds, direct, allocations } = req.body || {};
    if (!attackerId) {
      return res.status(400).json({ error: "attackerId required" });
    }
    res.json(storage.attack(attackerId, defenderIds, direct, allocations));
  });

  app.post("/api/game/deal", (_req, res) => {
    res.json(storage.dealCards());
  });

  app.post("/api/game/reset", (_req, res) => {
    res.json(storage.resetGame());
  });

  app.post("/api/game/add-bots", (_req, res) => {
    res.json(storage.addBots());
  });

  app.post("/api/game/join", (req, res) => {
    const { playerName } = req.body || {};
    res.json(storage.joinGame(playerName || "Player"));
  });

  app.post("/api/game/ai-step", async (_req, res) => {
    try {
      const state = storage.getGameState();
      const activePlayer = state.players.find(p => p.isActive);
      
      if (!activePlayer) {
        return res.json({ error: "No active player" });
      }

      const isBot = activePlayer.name !== "South Gate";
      
      if (!isBot) {
        return res.json({ message: "Active player is human", state });
      }

      const opponents = state.players.filter(p => p.id !== activePlayer.id);
      
      const decision = await aiBot.decideAction({
        phase: state.phase,
        player: activePlayer,
        opponents,
        hand: activePlayer.hand,
        battlefield: activePlayer.battlefield,
      });

      let result;
      
      if (decision.action === "play" && decision.cardId) {
        result = storage.playCard(decision.cardId);
      } else if (decision.action === "attack" && decision.cardId) {
        const defenderIds = decision.targetId ? [decision.targetId] : [];
        result = storage.attack(decision.cardId, defenderIds);
      } else {
        result = storage.endPhase();
      }

      res.json({ decision, result });
    } catch (error) {
      console.error("AI step error:", error);
      res.status(500).json({ error: "AI step failed", details: String(error) });
    }
  });

  app.post("/api/game/start-ai", (_req, res) => {
    gameLoop.start();
    res.json({ message: "AI autonomous play started" });
  });

  app.post("/api/game/stop-ai", (_req, res) => {
    gameLoop.stop();
    res.json({ message: "AI autonomous play stopped" });
  });

  app.get("/api/cards/image/:cardName", (req, res) => {
    const imageUrl = cardImageLoader.getImageUrl(req.params.cardName);
    res.json({ imageUrl });
  });

  app.post("/api/cards/refresh-images", (_req, res) => {
    cardImageLoader.refresh();
    res.json({ message: "Card images refreshed" });
  });

  app.post("/api/stack/push", (req, res) => {
    const { entry } = req.body || {};
    res.json(storage.pushStack(entry || { type: "generic" }));
  });

  app.post("/api/stack/resolve", (_req, res) => {
    res.json(storage.resolveStack());
  });

  app.post("/api/priority/pass", (_req, res) => {
    res.json(storage.passPriority());
  });

  app.get("/api/stack", (_req, res) => {
    res.json({ stack: (storage as any).stack ?? [] });
  });

  const httpServer = createServer(app);
  return httpServer;
}