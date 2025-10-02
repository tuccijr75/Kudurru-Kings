import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Crown, User } from "lucide-react";
import { ResourcePool } from "./ResourcePool";
import { GameCard } from "./GameCard";
import type { Player } from "@shared/schema";

interface PlayerZoneProps {
  player: Player;
  compact?: boolean;
  onResourceChange?: (type: "sinew" | "sigil" | "oath", value: number) => void;
}

export function PlayerZone({ player, compact = false, onResourceChange }: PlayerZoneProps) {
  const positionStyles = {
    top: "items-center",
    right: "items-end",
    bottom: "items-center",
    left: "items-start",
  };

  return (
    <div className={`flex flex-col gap-2 ${positionStyles[player.position]}`}>
      <Card className={`${compact ? "p-2" : "p-3"} min-w-64`}>
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
              player.isActive ? "bg-primary" : "bg-muted"
            }`}>
              <User className="w-4 h-4" />
            </div>
            <div>
              <p className="font-semibold text-sm" data-testid={`text-player-name-${player.id}`}>
                {player.name}
              </p>
              <p className="text-xs text-muted-foreground">{player.position}</p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1 px-2 py-1 bg-primary/20 rounded" data-testid={`marks-${player.id}`}>
              <Crown className="w-4 h-4 text-primary" />
              <span className="font-mono text-lg font-bold text-primary">{player.marks}</span>
            </div>
          </div>
        </div>

        {!compact && (
          <div className="mt-3 space-y-2">
            <ResourcePool
              type="sinew"
              value={player.resources.sinew}
              onChange={onResourceChange ? (v) => onResourceChange("sinew", v) : undefined}
            />
            <ResourcePool
              type="sigil"
              value={player.resources.sigil}
              onChange={onResourceChange ? (v) => onResourceChange("sigil", v) : undefined}
            />
            <ResourcePool
              type="oath"
              value={player.resources.oath}
              onChange={onResourceChange ? (v) => onResourceChange("oath", v) : undefined}
            />
          </div>
        )}
      </Card>

      {!compact && player.battlefield.length > 0 && (
        <div className="flex gap-2 flex-wrap max-w-md">
          {player.battlefield.slice(0, 3).map((card) => (
            <GameCard key={card.id} card={card} size="small" />
          ))}
        </div>
      )}

      {!compact && player.sites.length > 0 && (
        <div className="flex gap-2">
          {player.sites.map((site) => (
            <Badge key={site.id} className="bg-accent" data-testid={`site-${site.id}`}>
              {site.name}
            </Badge>
          ))}
        </div>
      )}
    </div>
  );
}
