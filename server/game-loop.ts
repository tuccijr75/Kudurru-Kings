import { storage } from "./storage";
import { aiBot } from "./ai-bot";

export class GameLoop {
  private running = false;
  private intervalId?: NodeJS.Timeout;

  start() {
    if (this.running) return;
    this.running = true;
    
    console.log("Game loop started - AI will play autonomously");
    
    this.intervalId = setInterval(async () => {
      await this.tick();
    }, 2000);
  }

  stop() {
    this.running = false;
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
    console.log("Game loop stopped");
  }

  private async tick() {
    try {
      const state = storage.getGameState();
      
      if (state.gameOver) {
        console.log("Game over, stopping loop");
        this.stop();
        return;
      }

      const activePlayer = state.players.find(p => p.isActive);
      if (!activePlayer) return;

      const isBot = activePlayer.name !== "South Gate";
      if (!isBot) return;

      console.log(`AI turn: ${activePlayer.name} (${state.phase} phase)`);

      const opponents = state.players.filter(p => p.id !== activePlayer.id);
      
      const decision = await aiBot.decideAction({
        phase: state.phase,
        player: activePlayer,
        opponents,
        hand: activePlayer.hand,
        battlefield: activePlayer.battlefield,
      });

      console.log(`AI decision:`, decision);

      if (decision.action === "play" && decision.cardId) {
        storage.playCard(decision.cardId);
      } else if (decision.action === "attack" && decision.cardId) {
        const defenderIds = decision.targetId ? [decision.targetId] : [];
        storage.attack(decision.cardId, defenderIds);
      } else {
        storage.endPhase();
      }
    } catch (error) {
      console.error("Game loop error:", error);
    }
  }
}

export const gameLoop = new GameLoop();