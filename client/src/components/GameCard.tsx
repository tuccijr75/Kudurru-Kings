import { Card as UICard } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Flame, Sparkles, Shield, Crown } from "lucide-react";
import type { Card } from "@shared/schema";

function parseKeywords(text?: string): string[] { const t=(text||"").toLowerCase(); const k:string[]=[]; if (t.includes("taunt")) k.push("Taunt"); if (t.includes("first strike")) k.push("First Strike"); return k; }

interface GameCardProps {
  card: Card;
  onClick?: () => void;
  selected?: boolean;
  size?: "small" | "normal" | "large";
}

const worldColors = {
  Mars: "bg-chart-1/20 border-chart-1/40",
  Earth: "bg-emerald-500/20 border-emerald-500/40",
  Moon: "bg-chart-2/20 border-chart-2/40",
  Nibiru: "bg-chart-4/20 border-chart-4/40",
};

const rarityColors = {
  low: "bg-muted",
  mid: "bg-chart-3",
  high: "bg-chart-2",
  rare: "bg-chart-4",
  super: "bg-primary",
};

export function GameCard({ card, onClick, selected, size = "normal" }: GameCardProps) {
  const sizeClasses = {
    small: "w-32",
    normal: "w-40",
    large: "w-56",
  };

  return (
    <UICard
      className={`${sizeClasses[size]} cursor-pointer transition-all hover-elevate active-elevate-2 ${
        selected ? "ring-2 ring-primary" : ""
      } ${worldColors[card.world]} relative overflow-visible`}
      onClick={onClick}
      data-testid={`card-${card.id}`}
    >
      <div className="p-3 space-y-2">
        <div className="flex items-start justify-between">
          <div className="flex gap-1">
            {card.costSinew > 0 && (
              <div className="flex items-center gap-0.5 text-chart-1">
                <Flame className="w-3 h-3" />
                <span className="text-xs font-mono">{card.costSinew}</span>
              </div>
            )}
            {card.costSigil > 0 && (
              <div className="flex items-center gap-0.5 text-chart-2">
                <Sparkles className="w-3 h-3" />
                <span className="text-xs font-mono">{card.costSigil}</span>
              </div>
            )}
            {card.costOath > 0 && (
              <div className="flex items-center gap-0.5 text-chart-3">
                <Shield className="w-3 h-3" />
                <span className="text-xs font-mono">{card.costOath}</span>
              </div>
            )}
          </div>
          <Badge className={`${rarityColors[card.rarity]} text-xs`} data-testid={`badge-rarity-${card.id}`}>
            {card.rarity}
          </Badge>
        </div>

        <div className="min-h-16 flex items-center justify-center bg-muted/30 rounded border border-border/50">
          <Crown className="w-8 h-8 text-muted-foreground/40" />
        </div>

        <div>
          <h3 className="font-semibold text-sm truncate" data-testid={`text-card-name-${card.id}`}>
            {card.name}
          </h3>
          <Badge variant="outline" className="text-xs mt-1" data-testid={`badge-type-${card.id}`}>
            {card.type}
          </Badge>
        </div>

        {(card.type === "Character" || card.type === "Enemy" || card.type === "Boss") && (
          <div className="flex gap-2 pt-1 border-t border-border/50">
            <div className="flex items-center gap-1">
              <span className="text-xs text-muted-foreground">⚔</span>
              <span className="font-mono text-sm font-bold" data-testid={`text-power-${card.id}`}>
                {card.power}
              </span>
            </div>
            <div className="flex items-center gap-1">
              <span className="text-xs text-muted-foreground">🛡</span>
              <span className="font-mono text-sm font-bold" data-testid={`text-armor-${card.id}`}>
                {card.armor}
              </span>
            </div>
          </div>
        )}

        {card.heat > 0 && (
          <div className="absolute top-1 right-1 flex items-center gap-0.5 bg-destructive/80 text-destructive-foreground px-1.5 py-0.5 rounded" data-testid={`heat-indicator-${card.id}`}>
            <Flame className="w-3 h-3" />
            <span className="text-xs font-mono font-bold">{card.heat}</span>
          </div>
        )}

        {card.attachedPet && (
          <div className="absolute bottom-1 right-1 w-6 h-6 bg-emerald-500/80 rounded-full flex items-center justify-center text-xs">
            🐾
          </div>
        )}

        {card.attachedRelic && (
          <div className="absolute bottom-1 left-1 w-6 h-6 bg-amber-500/80 rounded-full flex items-center justify-center text-xs">
            ⚡
          </div>
        )}
      </div>
    
      {(card as any).damage ? (
        <div className="absolute bottom-1 right-1 px-1 py-0.5 text-[10px] rounded bg-red-600/90 text-white">
          DMG {(card as any).damage}/{card.armor}
        </div>
      ) : null}
      {"summoning" in card && (card as any).summoning ? (
        <div className="absolute inset-0 bg-black/40 backdrop-blur-[1px] pointer-events-none rounded-xl" title="Can’t attack this turn" />
      ) : null}
    </UICard>
  );
}
