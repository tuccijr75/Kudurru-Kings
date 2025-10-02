import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { GameCard } from "./GameCard";
import { Badge } from "@/components/ui/badge";
import { Flame, Sparkles, Shield } from "lucide-react";
import type { Card, TestAxis } from "@shared/schema";
import { useState } from "react";

interface CombatModalProps {
  defenders?: Card[];
  allocation?: Record<string, number>;
  onAllocationChange?: (alloc: Record<string, number>) => void;
  open: boolean;
  onClose: () => void;
  attacker?: Card;
  defender?: Card;
}

export function CombatModal({ open, onClose, attacker, defender }: CombatModalProps) {
  const [selectedAxis, setSelectedAxis] = useState<TestAxis | null>(null);
  const [resourceCommit, setResourceCommit] = useState(0);

  const axisOptions: { axis: TestAxis; icon: any; label: string; color: string }[] = [
    { axis: "Stone", icon: Flame, label: "Stone (Sinew)", color: "text-chart-1" },
    { axis: "Veil", icon: Sparkles, label: "Veil (Sigil)", color: "text-chart-2" },
    { axis: "Oath", icon: Shield, label: "Oath (Command)", color: "text-chart-3" },
  ];

  const calculateScore = (card?: Card) => {
    if (!card) return 0;
    const baseScore = card.power;
    const resourceBonus = resourceCommit * 2;
    return baseScore + resourceBonus;
  };

  const handleConfirm = () => {
    console.log("Combat resolved:", { selectedAxis, resourceCommit });
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl">
        <DialogHeader>
          <DialogTitle className="font-serif text-2xl text-primary">Combat Engagement</DialogTitle>
        </DialogHeader>

        <div className="grid grid-cols-2 gap-6 py-4">
          <div className="space-y-2">
            <p className="text-sm font-semibold text-muted-foreground">Attacker</p>
            {attacker && <GameCard card={attacker} size="large" />}
            <div className="p-3 bg-muted/50 rounded">
              <p className="text-sm font-semibold mb-1">Attack Score</p>
              <p className="text-3xl font-mono font-bold text-primary" data-testid="text-attack-score">
                {calculateScore(attacker)}
              </p>
            </div>
          </div>

          <div className="space-y-2">
            <p className="text-sm font-semibold text-muted-foreground">Defender</p>
            {defender && <GameCard card={defender} size="large" />}
            <div className="p-3 bg-muted/50 rounded">
              <p className="text-sm font-semibold mb-1">Defense Score</p>
              <p className="text-3xl font-mono font-bold text-chart-3" data-testid="text-defense-score">
                {calculateScore(defender)}
              </p>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <p className="text-sm font-semibold mb-2">Select Test Axis</p>
            <div className="grid grid-cols-3 gap-2">
              {axisOptions.map(({ axis, icon: Icon, label, color }) => (
                <Button
                  key={axis}
                  variant={selectedAxis === axis ? "default" : "outline"}
                  onClick={() => setSelectedAxis(axis)}
                  className="justify-start gap-2"
                  data-testid={`button-axis-${axis.toLowerCase()}`}
                >
                  <Icon className={`w-4 h-4 ${selectedAxis === axis ? "" : color}`} />
                  {label}
                </Button>
              ))}
            </div>
          </div>

          <div>
            <p className="text-sm font-semibold mb-2">
              Commit Resources (0-2) <span className="text-muted-foreground">+{resourceCommit * 2} bonus</span>
            </p>
            <div className="flex gap-2">
              {[0, 1, 2].map((value) => (
                <Button
                  key={value}
                  variant={resourceCommit === value ? "default" : "outline"}
                  onClick={() => setResourceCommit(value)}
                  data-testid={`button-resource-${value}`}
                >
                  {value}
                </Button>
              ))}
            </div>
          </div>
        
          {/* Damage Allocation */}
          {attacker && defenders.length > 0 && (
            <div className="col-span-2 border-t pt-3 mt-2">
              <p className="text-sm font-semibold mb-2">Damage Allocation</p>
              {defenders.map((d) => {
                const val = allocation[d.id] ?? 0;
                return (
                  <div key={d.id} className="flex items-center gap-3 py-1">
                    <span className="min-w-[140px] text-xs">{d.name}</span>
                    <input type="range" min={0} max={attacker.power} value={val}
                      onChange={(e) => onAllocationChange?.({ ...allocation, [d.id]: parseInt(e.target.value, 10) })}
                      className="w-64" />
                    <span className="text-xs w-10 text-right">{val}</span>
                  </div>
                );
              })}
              <div className="text-xs text-muted-foreground mt-1">
                Remaining Damage: {Math.max(0, attacker.power - Object.values(allocation || {}).reduce((a: any,b: any)=>a+(b as number), 0))}
              </div>
            </div>
          )}

        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} data-testid="button-cancel-combat">
            Cancel
          </Button>
          <Button onClick={handleConfirm} disabled={!selectedAxis} data-testid="button-confirm-combat">
            Resolve Combat
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
