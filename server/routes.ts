
import type { Express } from "express";
import { createServer, type Server } from "http";
import { storage } from "./storage";
import { z } from "zod";

const createUserSchema = z.object({
  username: z.string().min(2),
  displayName: z.string().min(1),
});

export async function registerRoutes(app: Express): Promise<Server> {
  app.get("/api/health", (_req, res) => res.json({ ok: true, service: "KudurruKings", ts: Date.now() }));

  // Users demo
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
    if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
    const created = await storage.createUser(parsed.data);
    res.status(201).json(created);
  });

  // Game
  app.get("/api/game", (_req, res) => res.json(storage.getGameState()));
  app.post("/api/game/play", (req, res) => {
    const { cardId } = (req.body || {});
    res.json(storage.playCard(cardId));
  });
  app.post("/api/game/end-phase", (_req, res) => res.json(storage.endPhase()));
  app.post("/api/game/attack", (req, res) => {
    const { attackerId, defenderIds, direct, allocations } = (req.body || {});
    if (!attackerId) return res.status(400).json({ error: "attackerId required" });
    res.json(storage.attack(attackerId, defenderIds, direct, allocations));
  });

  // Stack
  app.post("/api/stack/push", (req, res) => { const { entry } = (req.body || {}); res.json(storage.pushStack(entry || { type: "generic" })); });
  app.post("/api/stack/resolve", (_req, res) => { res.json(storage.resolveStack()); });
  app.post("/api/priority/pass", (_req, res) => { res.json(storage.passPriority()); });
  app.get("/api/stack", (_req, res) => { res.json({ stack: (storage as any).stack ?? [] }); });

  const httpServer = createServer(app);
  return httpServer;
}
