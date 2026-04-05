import { GameCard } from "./GameCard";
import type { Card } from "@shared/schema";
import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useState } from "react";

interface HandAreaProps {
  cards: Card[];
  onCardClick?: (card: Card) => void;
  selectedCardId?: string;
}

export function HandArea({ cards, onCardClick, selectedCardId }: HandAreaProps) {
  const [scrollPosition, setScrollPosition] = useState(0);

  const scroll = (direction: "left" | "right") => {
    const container = document.getElementById("hand-container");
    if (container) {
      const scrollAmount = 200;
      const newPosition = direction === "left" 
        ? Math.max(0, scrollPosition - scrollAmount)
        : scrollPosition + scrollAmount;
      container.scrollLeft = newPosition;
      setScrollPosition(newPosition);
    }
  };

  return (
    <div className="relative bg-card border-t border-border p-4">
      <div className="flex items-center justify-between mb-2">
        <p className="text-sm font-semibold">
          Hand ({cards.length}/9)
        </p>
        <div className="flex gap-1">
          <Button
            size="icon"
            variant="ghost"
            onClick={() => scroll("left")}
            data-testid="button-scroll-left"
          >
            <ChevronLeft className="w-4 h-4" />
          </Button>
          <Button
            size="icon"
            variant="ghost"
            onClick={() => scroll("right")}
            data-testid="button-scroll-right"
          >
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
      </div>

      <div
        id="hand-container"
        className="flex gap-3 overflow-x-auto pb-2 scroll-smooth"
        style={{ scrollbarWidth: "thin" }}
      >
        {cards.map((card) => (
          <GameCard
            key={card.id}
            card={card}
            onClick={() => onCardClick?.(card)}
            selected={card.id === selectedCardId}
            size="normal"
          />
        ))}
      </div>
    </div>
  );
}
