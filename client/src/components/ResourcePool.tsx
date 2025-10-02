import { Flame, Sparkles, Shield } from "lucide-react";
import { Badge } from "@/components/ui/badge";

interface ResourcePoolProps {
  type: "sinew" | "sigil" | "oath";
  value: number;
  onChange?: (value: number) => void;
}

const resourceConfig = {
  sinew: {
    icon: Flame,
    label: "Sinew",
    color: "text-chart-1",
    bg: "bg-chart-1/10",
  },
  sigil: {
    icon: Sparkles,
    label: "Sigil",
    color: "text-chart-2",
    bg: "bg-chart-2/10",
  },
  oath: {
    icon: Shield,
    label: "Oath",
    color: "text-chart-3",
    bg: "bg-chart-3/10",
  },
};

export function ResourcePool({ type, value, onChange }: ResourcePoolProps) {
  const config = resourceConfig[type];
  const Icon = config.icon;

  return (
    <div className="flex items-center gap-2">
      <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md ${config.bg}`}>
        <Icon className={`w-4 h-4 ${config.color}`} />
        <span className={`font-mono text-lg font-bold ${config.color}`} data-testid={`text-${type}-value`}>
          {value}
        </span>
      </div>
      {onChange && (
        <div className="flex gap-1">
          <button
            onClick={() => onChange(Math.max(0, value - 1))}
            className="w-6 h-6 rounded text-xs hover-elevate active-elevate-2 bg-card border"
            data-testid={`button-${type}-decrement`}
          >
            -
          </button>
          <button
            onClick={() => onChange(value + 1)}
            className="w-6 h-6 rounded text-xs hover-elevate active-elevate-2 bg-card border"
            data-testid={`button-${type}-increment`}
          >
            +
          </button>
        </div>
      )}
    </div>
  );
}
