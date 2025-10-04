import { Card as CardType } from "@shared/schema";
import { Card } from "@/components/ui/card";

interface EnhancedGameCardProps {
  card: CardType;
  size?: "tiny" | "small" | "medium" | "large";
  selected?: boolean;
  onClick?: () => void;
}

export function EnhancedGameCard({ card, size = "medium", selected, onClick }: EnhancedGameCardProps) {
  const sizeClasses = {
    tiny: "w-20 h-28",
    small: "w-32 h-48",
    medium: "w-48 h-72",
    large: "w-64 h-96"
  };

  const worldColors = {
    Earth: "from-green-900 to-green-700",
    Mars: "from-red-900 to-red-700",
    Moon: "from-purple-900 to-purple-700",
    Nibiru: "from-gray-900 to-gray-700",
    Venus: "from-pink-900 to-pink-700"
  };

  return (
    <Card 
      className={`${sizeClasses[size]} relative overflow-hidden cursor-pointer transition-all
        ${selected ? 'ring-4 ring-yellow-500 scale-105' : 'hover:scale-102'}
        bg-gradient-to-b ${worldColors[card.world]} shadow-xl`}
      onClick={onClick}
    >
      <div className="absolute inset-0 opacity-20 bg-[radial-gradient(circle_at_50%_50%,_rgba(59,130,246,0.1),transparent)]" />
      
      <div className="relative h-1/2 flex items-center justify-center p-4">
        <div className="w-full aspect-square rounded-full border-4 border-yellow-600 overflow-hidden bg-black shadow-lg">
          {card.imageUrl ? (
            <img 
              src={card.imageUrl} 
              alt={card.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-yellow-600 text-4xl font-bold">
              {card.name.charAt(0)}
            </div>
          )}
        </div>
      </div>

      <div className="relative h-1/2 p-2 flex flex-col">
        <div className="bg-gradient-to-r from-yellow-900 to-yellow-700 px-2 py-1 rounded text-center shadow-md">
          <h3 className="font-serif text-yellow-100 text-sm font-bold truncate">
            {card.name}
          </h3>
        </div>

        <div className="flex-1 bg-gradient-to-b from-amber-100 to-amber-200 rounded mt-1 p-2 shadow-inner">
          <p className="text-xs text-gray-800 leading-tight">
            {card.text || "No special abilities"}
          </p>
        </div>

        <div className="flex gap-1 mt-1">
          {card.costSinew > 0 && (
            <div className="bg-red-600 text-white text-xs px-1.5 py-0.5 rounded font-bold shadow">
              {card.costSinew}S
            </div>
          )}
          {card.costSigil > 0 && (
            <div className="bg-blue-600 text-white text-xs px-1.5 py-0.5 rounded font-bold shadow">
              {card.costSigil}G
            </div>
          )}
          {card.costOath > 0 && (
            <div className="bg-yellow-600 text-white text-xs px-1.5 py-0.5 rounded font-bold shadow">
              {card.costOath}O
            </div>
          )}
        </div>

        <div className="bg-gradient-to-r from-yellow-900 to-yellow-700 px-2 py-1 rounded text-center mt-1 shadow-md">
          <span className="font-mono text-yellow-100 font-bold text-sm">
            {card.power} / {card.armor}
          </span>
        </div>

        {card.heat > 0 && (
          <div className="absolute top-2 right-2 bg-orange-500 text-white text-xs px-2 py-1 rounded-full font-bold shadow-lg">
            {card.heat}
          </div>
        )}
      </div>

      <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-3xl">
        ⚜
      </div>
    </Card>
  );
}