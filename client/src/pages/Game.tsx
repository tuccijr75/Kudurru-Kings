import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { CentralPlaza } from "@/components/CentralPlaza";
import { PlayerZone } from "@/components/PlayerZone";
import { HandArea } from "@/components/HandArea";
import { PhaseIndicator } from "@/components/PhaseIndicator";
import { CombatModal } from "@/components/CombatModal";
import { InteractiveTutorial } from "@/components/InteractiveTutorial";
import type { Player, Phase, Card } from "@shared/schema";
import { api } from "@/lib/api";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";

type GameState = { 
  phase: Phase; 
  players: Player[]; 
  gameOver?: boolean; 
  winnerId?: string 
};

export default function Game() {
  const [currentPhase, setCurrentPhase] = useState<Phase>("Main");
  const [combatOpen, setCombatOpen] = useState(false);
  const [players, setPlayers] = useState<Player[]>([]);
  const [selectedCard, setSelectedCard] = useState<Card | undefined>();
  const [selectedAttacker, setSelectedAttacker] = useState<Card | undefined>();
  const [selectedDefenders, setSelectedDefenders] = useState<Card[]>([]);
  const [allocations, setAllocations] = useState<Record<string, number>>({});
  const [stackEntries, setStackEntries] = useState<any[]>([]);
  const [gameOver, setGameOver] = useState(false);
  const [winnerName, setWinnerName] = useState<string | undefined>(undefined);
  const [tutorialEnabled, setTutorialEnabled] = useState(false);

  const fetchGameState = async () => {
    try {
      const g = await api<GameState>("/api/game");
      setCurrentPhase(g.phase);
      setPlayers(g.players);
      setGameOver(!!g.gameOver);
      setWinnerName((g.players || []).find((p: any) => p.id === g.winnerId)?.name);
    } catch (error) {
      console.error("Failed to fetch game state:", error);
    }
  };

  useEffect(() => {
    let cancelled = false;
    
    fetchGameState();
    
    const id = setInterval(async () => {
      if (cancelled) return;
      try {
        const s = await api<{ stack: any[] }>("/api/stack");
        setStackEntries(s.stack || []);
      } catch {}
    }, 1000);
    
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  const samplePlayers: Player[] = [
    {
      id: "p1",
      name: "North Gate",
      position: "top",
      hand: [],
      battlefield: [],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 5, sigil: 5, oath: 5 },
      marks: 10,
      isActive: false,
    },
    {
      id: "p2",
      name: "East Gate",
      position: "right",
      hand: [],
      battlefield: [],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 5, sigil: 5, oath: 5 },
      marks: 10,
      isActive: false,
    },
    {
      id: "p3",
      name: "South Gate",
      position: "bottom",
      hand: [],
      battlefield: [],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 5, sigil: 5, oath: 5 },
      marks: 10,
      isActive: true,
    },
    {
      id: "p4",
      name: "West Gate",
      position: "left",
      hand: [],
      battlefield: [],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 5, sigil: 5, oath: 5 },
      marks: 10,
      isActive: false,
    },
  ];

  const playersState = players.length ? players : samplePlayers;
  const currentPlayer = players.find((p) => p.isActive) || playersState[2];

  const handleDefenderToggle = (card: Card) => {
    setSelectedDefenders((arr) =>
      arr.find((x) => x.id === card.id)
        ? arr.filter((x) => x.id !== card.id)
        : [...arr, card]
    );
  };

  const handleNextPhase = async () => {
    try {
      const g = await api<GameState>("/api/game/end-phase", { method: "POST" });
      setCurrentPhase(g.phase);
      setPlayers(g.players);
      setGameOver(!!g.gameOver);
      setWinnerName((g.players || []).find((p: any) => p.id === g.winnerId)?.name);
    } catch (error) {
      console.error("Failed to advance phase:", error);
    }
  };

  const handleJoinRoom = async () => {
    try {
      const g = await api<GameState>("/api/game/join", { 
        method: "POST",
        body: JSON.stringify({ playerName: "New Player" })
      });
      setPlayers(g.players);
    } catch (error) {
      console.error("Failed to join room:", error);
    }
  };

  const handleAddBots = async () => {
    try {
      const g = await api<GameState>("/api/game/add-bots", { method: "POST" });
      setPlayers(g.players);
    } catch (error) {
      console.error("Failed to add bots:", error);
    }
  };

  const handleDeal6 = async () => {
    try {
      const g = await api<GameState>("/api/game/deal", { method: "POST" });
      setPlayers(g.players);
    } catch (error) {
      console.error("Failed to deal cards:", error);
    }
  };

  const handleResetMatch = async () => {
    try {
      const g = await api<GameState>("/api/game/reset", { method: "POST" });
      setCurrentPhase(g.phase);
      setPlayers(g.players);
      setGameOver(false);
      setWinnerName(undefined);
      setSelectedCard(undefined);
      setSelectedDefenders([]);
    } catch (error) {
      console.error("Failed to reset match:", error);
    }
  };

  const handlePlayCard = async () => {
    if (!selectedCard) {
      console.log("No card selected");
      return;
    }
    
    console.log("Playing card:", selectedCard.name, selectedCard.id);
    
    try {
      const g = await api<GameState>("/api/game/play", {
        method: "POST",
        body: JSON.stringify({ cardId: selectedCard.id })
      });
      
      console.log("Response from play:", g);
      
      setCurrentPhase(g.phase);
      setPlayers(g.players);
      setSelectedCard(undefined);
      
      console.log("Updated players:", g.players);
      console.log("South Gate battlefield:", g.players.find(p => p.name === "South Gate")?.battlefield);
    } catch (error) {
      console.error("Failed to play card:", error);
    }
  };

  const handleAIStep = async () => {
    try {
      const response = await api<any>("/api/game/ai-step", { method: "POST" });
      console.log("AI decision:", response.decision);
      console.log("AI result:", response.result);
      
      if (response.result) {
        setCurrentPhase(response.result.phase);
        setPlayers(response.result.players);
      }
    } catch (error) {
      console.error("Failed to execute AI step:", error);
    }
  };

  return (
    <div className="h-screen flex flex-col bg-background">
      <header className="border-b border-border bg-card p-3">
        <div className="flex items-center justify-between">
          <h1 className="font-serif text-2xl font-bold text-primary" data-testid="text-game-title">
            KUDURRU KINGS — Head-to-Head Client (4 Players)
          </h1>
          <div className="flex gap-2">
            <div className="ml-4 px-2 py-1 border rounded max-h-28 overflow-auto text-xs min-w-[180px]">
              <div className="font-semibold mb-1">Stack</div>
              {stackEntries.length === 0 ? (
                <div className="text-muted-foreground">Empty</div>
              ) : (
                stackEntries.map((e, i) => (
                  <div key={i} className="border-b py-0.5">
                    {e.type || "item"} {e.id}
                  </div>
                ))
              )}
            </div>
            <Button variant="outline" size="sm" onClick={handleJoinRoom} data-testid="button-join-room">
              Join Room
            </Button>
            <Button variant="outline" size="sm" onClick={handleNextPhase} data-testid="button-next-phase">
              Next Phase
            </Button>
            <Button variant="outline" size="sm" onClick={handleAddBots} data-testid="button-add-bots">
              Add 3 Bots
            </Button>
            <Button variant="outline" size="sm" onClick={handleDeal6} data-testid="button-deal-6">
              Deal 6
            </Button>
            <Button variant="outline" size="sm" onClick={handleResetMatch} data-testid="button-reset-match">
              Reset Match
            </Button>
            <Button variant="outline" size="sm" onClick={handleAIStep} data-testid="button-ai-step">
              AI Step
            </Button>
            <Button variant="outline" size="sm" data-testid="button-toggle-sandbox">
              Toggle Sandbox
            </Button>
            <Button 
              variant="outline" 
              size="sm" 
              onClick={() => setTutorialEnabled(true)} 
              data-testid="button-start-tutorial"
            >
              Start Tutorial
            </Button>
            <Button variant="outline" size="sm" data-testid="button-open-library">
              Open Library
            </Button>
          </div>
        </div>

        <div className="mt-3 flex items-center justify-between">
          <div className="flex gap-8">
            <div>
              <p className="text-xs text-muted-foreground mb-1">Type</p>
              <div className="flex gap-1">
                {["All", "Boss", "Character", "Enemy", "Pet", "Relic", "Site", "Rune"].map((type) => (
                  <Button
                    key={type}
                    variant="outline"
                    size="sm"
                    className="h-7 text-xs"
                    data-testid={`filter-type-${type.toLowerCase()}`}
                  >
                    {type}
                  </Button>
                ))}
              </div>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">Rarity</p>
              <div className="flex gap-1">
                {["All", "Low", "Mid", "Rare"].map((rarity) => (
                  <Button
                    key={rarity}
                    variant="outline"
                    size="sm"
                    className="h-7 text-xs"
                    data-testid={`filter-rarity-${rarity.toLowerCase()}`}
                  >
                    {rarity}
                  </Button>
                ))}
              </div>
            </div>
          </div>
          <div className="flex gap-2 items-center">
            <span className="text-sm text-muted-foreground">Zoom:</span>
            <input
              type="range"
              min="50"
              max="150"
              defaultValue="100"
              className="w-32"
              data-testid="slider-zoom"
            />
          </div>
        </div>
      </header>

      <div className="flex-1 relative overflow-hidden">
        <div className="absolute inset-0 flex flex-col">
          {/* Top section - North player and their battlefield */}
          <div className="flex justify-center p-4">
            <PlayerZone
              player={playersState[0]}
              compact
              onBattlefieldCardClick={handleDefenderToggle}
              selectedIds={selectedDefenders.map((x) => x.id)}
            />
          </div>

          {/* Middle section - Side players, plaza, and South player */}
          <div className="flex-1 grid grid-cols-3 gap-4 px-4">
            {/* West Gate - Left */}
            <div className="flex items-center justify-start">
              <PlayerZone
                player={playersState[3]}
                compact
                onBattlefieldCardClick={handleDefenderToggle}
                selectedIds={selectedDefenders.map((x) => x.id)}
              />
            </div>

            {/* Center - Plaza and Phase */}
            <div className="flex flex-col items-center justify-center gap-4">
              <CentralPlaza />
              <div className="flex gap-4">
                <div className="text-center">
                  <p className="text-sm text-muted-foreground mb-2">Phase:</p>
                  <PhaseIndicator currentPhase={currentPhase} />
                </div>
                <div className="text-center">
                  <p className="text-sm text-muted-foreground mb-2">Analyzer</p>
                  <Button
                    variant="outline"
                    onClick={() => setCombatOpen(true)}
                    data-testid="button-open-analyzer"
                  >
                    Start Combat
                  </Button>
                </div>
              </div>
            </div>

            {/* East Gate - Right */}
            <div className="flex items-center justify-end">
              <PlayerZone
                player={playersState[1]}
                compact
                onBattlefieldCardClick={handleDefenderToggle}
                selectedIds={selectedDefenders.map((x) => x.id)}
              />
            </div>
          </div>

          {/* South player - Your zone */}
          <div className="flex justify-center p-4">
            <PlayerZone
              player={playersState[2]}
              compact
              onBattlefieldCardClick={handleDefenderToggle}
              selectedIds={selectedDefenders.map((x) => x.id)}
            />
          </div>
        </div>
      </div>

      <div className="border-t border-border">
        <div className="grid grid-cols-2 gap-4 p-4">
          <div>
            <p className="text-xs text-muted-foreground mb-2" data-testid="text-p4-hand-label">
              P4 Hand - Deck 6
            </p>
            <div className="h-12 bg-muted/30 rounded border border-dashed border-border"></div>
          </div>
          <div>
            <p className="text-xs text-muted-foreground mb-2" data-testid="text-p3-hand-label">
              {currentPlayer.name} Hand ({currentPlayer.hand.length}) - Deck 6
            </p>
            <HandArea
              cards={currentPlayer.hand}
              selectedCardId={selectedCard?.id}
              onCardClick={setSelectedCard}
            />
          </div>
        </div>

        <div className="px-4 pb-4 flex gap-12 justify-center">
          <Button onClick={handlePlayCard} data-testid="button-play">Play</Button>
          <Button data-testid="button-move">Move</Button>
          <Button data-testid="button-invoke">Invoke</Button>
          <Button onClick={handleNextPhase} data-testid="button-end">
            End
          </Button>
        </div>
      </div>

      <CombatModal
        open={combatOpen}
        onClose={() => setCombatOpen(false)}
        defenders={selectedDefenders}
        allocation={allocations}
        onAllocationChange={setAllocations}
        attacker={selectedAttacker}
        defender={players[0]?.battlefield[0]}
      />

      <Dialog open={gameOver} onOpenChange={(o) => o || setGameOver(false)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle data-testid="game-over-title">Game Over</DialogTitle>
          </DialogHeader>
          <div className="text-sm">Winner: {winnerName || "Unknown"}</div>
          <DialogFooter>
            <Button onClick={() => window.location.reload()}>New Game</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <InteractiveTutorial
        phase={currentPhase}
        handSize={currentPlayer.hand.length}
        battlefieldSize={currentPlayer.battlefield.length}
        selectedCard={selectedCard}
        onComplete={() => setTutorialEnabled(false)}
        enabled={tutorialEnabled}
      />
    </div>
  );
}