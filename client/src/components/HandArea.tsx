import { EnhancedGameCard } from "./EnhancedGameCard";
import type { Card } from "@shared/schema";

interface HandAreaProps {
  cards: Card[];
  selectedCardId?: string;
  onCardClick?: (card: Card) => void;
}

export function HandArea({ cards, selectedCardId, onCardClick }: HandAreaProps) {
  if (!cards || cards.length === 0) {
    return (
      <div className="flex items-center justify-center h-32 bg-muted/30 rounded border border-dashed border-border">
        <p className="text-sm text-muted-foreground">No cards in hand</p>
      </div>
    );
  }

  return (
    <div className="flex gap-2 overflow-x-auto pb-2">
      {cards.map((card) => (
        <EnhancedGameCard
          key={card.id}
          card={card}
          size="small"
          selected={card.id === selectedCardId}
          onClick={() => onCardClick?.(card)}
        />
      ))}
    </div>
  );
}