import OpenAI from "openai";
import type { Player, Card, Phase } from "@shared/schema";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

interface GameContext {
  phase: Phase;
  player: Player;
  opponents: Player[];
  hand: Card[];
  battlefield: Card[];
}

export class AIBot {
  async decideAction(context: GameContext): Promise<{
    action: "play" | "attack" | "end";
    cardId?: string;
    targetId?: string;
  }> {
    const prompt = this.buildPrompt(context);

    try {
      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are a Kudurru Kings card game AI. You make strategic decisions to win. Respond ONLY with valid JSON in the format: {\"action\": \"play\" | \"attack\" | \"end\", \"cardId\": \"string\" | null, \"targetId\": \"string\" | null}"
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 150,
      });

      const response = completion.choices[0].message.content;
      if (!response) {
        return { action: "end" };
      }

      const decision = JSON.parse(response);
      return decision;
    } catch (error) {
      console.error("AI decision error:", error);
      return { action: "end" };
    }
  }

  private buildPrompt(context: GameContext): string {
    const { phase, player, opponents, hand, battlefield } = context;

    let prompt = `Game State:\n`;
    prompt += `Phase: ${phase}\n`;
    prompt += `Your marks: ${player.marks}\n`;
    prompt += `Your resources: Sinew ${player.resources.sinew}, Sigil ${player.resources.sigil}, Oath ${player.resources.oath}\n\n`;

    if (phase === "Main" && hand.length > 0) {
      prompt += `Your hand (${hand.length} cards):\n`;
      hand.forEach(card => {
        prompt += `- ${card.id}: ${card.name} (${card.type}) - Cost: S${card.costSinew} G${card.costSigil} O${card.costOath} - Power ${card.power}/${card.armor}\n`;
      });
      prompt += `\nDecide: Which card to play? (return cardId) Or end phase? (return action: "end")\n`;
    }

    if (phase === "Battle" && battlefield.length > 0) {
      prompt += `Your battlefield:\n`;
      battlefield.forEach(card => {
        prompt += `- ${card.id}: ${card.name} - Power ${card.power}/${card.armor}, Heat: ${(card as any).heat || 0}\n`;
      });
      
      const opponent = opponents[0];
      prompt += `\nOpponent (${opponent.name}) - Marks: ${opponent.marks}\n`;
      prompt += `Opponent battlefield:\n`;
      opponent.battlefield.forEach(card => {
        prompt += `- ${card.id}: ${card.name} - Power ${card.power}/${card.armor}\n`;
      });
      
      prompt += `\nDecide: Which creature to attack with? (return cardId and optionally targetId for blocker) Or end phase?\n`;
    }

    if (phase === "Upkeep" || phase === "End") {
      prompt += `Phase: ${phase} - Just return action: "end" to continue\n`;
    }

    return prompt;
  }
}

export const aiBot = new AIBot();