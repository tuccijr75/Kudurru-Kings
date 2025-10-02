import { Badge } from "@/components/ui/badge";
import type { Phase } from "@shared/schema";

interface PhaseIndicatorProps {
  currentPhase: Phase;
}

const phases: Phase[] = ["Upkeep", "Main", "Battle", "End"];

export function PhaseIndicator({ currentPhase }: PhaseIndicatorProps) {
  return (
    <div className="flex gap-2">
      {phases.map((phase) => (
        <Badge
          key={phase}
          variant={currentPhase === phase ? "default" : "outline"}
          className={currentPhase === phase ? "bg-primary" : ""}
          data-testid={`phase-${phase.toLowerCase()}`}
        >
          {phase}
        </Badge>
      ))}
    </div>
  );
}
