import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { CentralPlaza } from "@/components/CentralPlaza";
import { PlayerZone } from "@/components/PlayerZone";
import { HandArea } from "@/components/HandArea";
import { PhaseIndicator } from "@/components/PhaseIndicator";
import { CombatModal } from "@/components/CombatModal";
import type { Player, Phase, Card } from "@shared/schema";
import { api } from "@/lib/api";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogTrigger } from "@/components/ui/dialog";

type GameState = { phase: Phase; players: Player[]; gameOver?: boolean; winnerId?: string };

export default function Game() {
  const [currentPhase, setCurrentPhase] = useState<Phase>("Main");
  const [combatOpen, setCombatOpen] = useState(false);
  const [players, setPlayers] = useState<Player[]>([]);
  const [selectedCard, setSelectedCard] = useState<Card | undefined>();

  useEffect(() => {
    let cancelled = false;
    (async function init(){ const g = await api<GameState>("/api/game"); setCurrentPhase(g.phase); setPlayers(g.players); setGameOver(!!g.gameOver); setWinnerName((g.players||[]).find((p:any)=>p.id===g.winnerId)?.name); })();
    const id = setInterval(async () => { if (cancelled) return; try { const s = await api<{stack:any[]}>("/api/stack"); setStackEntries(s.stack||[]); } catch {} }, 1000);
    return () => { cancelled = true; clearInterval(id); };
  }, []);
  const [selectedAttacker, setSelectedAttacker] = useState<Card | undefined>();
  const [selectedDefenders, setSelectedDefenders] = useState<Card[]>([]);
  const [allocations, setAllocations] = useState<Record<string, number>>({});
  const [stackEntries, setStackEntries] = useState<any[]>([]);
  const [gameOver, setGameOver] = useState(false);
  const [winnerName, setWinnerName] = useState<string | undefined>(undefined);
  const [selectedCard, setSelectedCard] = useState<Card | undefined>();

  useEffect(() => {
    let cancelled = false;
    (async function init(){ const g = await api<GameState>("/api/game"); setCurrentPhase(g.phase); setPlayers(g.players); setGameOver(!!g.gameOver); setWinnerName((g.players||[]).find((p:any)=>p.id===g.winnerId)?.name); })();
    const id = setInterval(async () => { if (cancelled) return; try { const s = await api<{stack:any[]}>("/api/stack"); setStackEntries(s.stack||[]); } catch {} }, 1000);
    return () => { cancelled = true; clearInterval(id); };
  }, []);

  const samplePlayers: Player[] = [
    {
      id: "p1",
      name: "P1 Lapis",
      position: "top",
      hand: [],
      battlefield: [
        {
          id: "c1",
          name: "Influence 0 Tribute 0 Oath 0/2",
          type: "Character",
          world: "Moon",
          rarity: "mid",
          power: 4,
          armor: 2,
          costSinew: 0,
          costSigil: 1,
          costOath: 1,
          text: "",
          heat: 0,
        },
      ],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 2, sigil: 3, oath: 1 },
      marks: 2,
      isActive: false,
    },
    {
      id: "p2",
      name: "P2 Jade",
      position: "right",
      hand: [],
      battlefield: [
        {
          id: "c2",
          name: "Influence 0 Tribute 0 Oath 0/2",
          type: "Character",
          world: "Earth",
          rarity: "mid",
          power: 5,
          armor: 2,
          costSinew: 1,
          costSigil: 2,
          costOath: 0,
          text: "",
          heat: 0,
        },
      ],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 1, sigil: 4, oath: 2 },
      marks: 3,
      isActive: false,
    },
    {
      id: "p3",
      name: "P3 Amethyst",
      position: "bottom",
      hand: [
        {
          id: "h1",
          name: "Fire Warrior",
          type: "Character",
          world: "Mars",
          rarity: "high",
          power: 6,
          armor: 3,
          costSinew: 3,
          costSigil: 0,
          costOath: 1,
          text: "",
          heat: 0,
        },
        {
          id: "h2",
          name: "Mystic Charm",
          type: "Relic",
          world: "Moon",
          rarity: "mid",
          power: 0,
          armor: 0,
          costSinew: 0,
          costSigil: 2,
          costOath: 0,
          text: "+2 to all Veil tests",
          heat: 0,
        },
        {
          id: "h3",
          name: "Battle Hound",
          type: "Pet",
          world: "Nibiru",
          rarity: "low",
          power: 0,
          armor: 0,
          costSinew: 1,
          costSigil: 0,
          costOath: 0,
          text: "+1 armor",
          heat: 0,
        },
        {
          id: "h4",
          name: "Ancient Temple",
          type: "Site",
          world: "Earth",
          rarity: "rare",
          power: 0,
          armor: 0,
          costSinew: 0,
          costSigil: 2,
          costOath: 1,
          text: "+1 Sigil at upkeep",
          heat: 0,
        },
      ],
      battlefield: [],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 3, sigil: 2, oath: 2 },
      marks: 1,
      isActive: true,
    },
    {
      id: "p4",
      name: "P4 Ember",
      position: "left",
      hand: [],
      battlefield: [
        {
          id: "c4",
          name: "Influence 0 Tribute 0 Oath 0/2",
          type: "Character",
          world: "Mars",
          rarity: "low",
          power: 3,
          armor: 1,
          costSinew: 2,
          costSigil: 0,
          costOath: 0,
          text: "",
          heat: 0,
        },
      ],
      sites: [],
      capture: [],
      discard: [],
      deck: [],
      resources: { sinew: 4, sigil: 1, oath: 1 },
      marks: 2,
      isActive: false,
    },
  ];

  const playersState = players.length ? players : samplePlayers;
  const currentPlayer = players.find((p) => p.isActive) || players[2];

  const phases: Phase[] = ["Upkeep", "Main", "Battle", "End"];
  const nextPhase = () => {
    const currentIndex = phases.indexOf(currentPhase);
    const nextIndex = (currentIndex + 1) % phases.length;
    setCurrentPhase(phases[nextIndex]);
    console.log("Phase changed to:", phases[nextIndex]);
  };

  return (
    <div className="h-screen flex flex-col bg-background">
      <header className="border-b border-border bg-card p-3">
        <div className="flex items-center justify-between">
          <h1 className="font-serif text-2xl font-bold text-primary" data-testid="text-game-title">
            KUDURRU KINGS — Head-to-Head Client (4 Players)
          </h1>
          <div className="flex gap-2">
          <div className="ml-4 px-2 py-1 border rounded max-h-28 overflow-auto text-xs min-w-[180px]"><div className="font-semibold mb-1">Stack</div>{stackEntries.length===0? <div className="text-muted-foreground">Empty</div> : stackEntries.map((e,i)=>(<div key={i} className="border-b py-0.5">{e.type||"item"} {e.id}</div>))}</div>
            <Button variant="outline" size="sm" data-testid="button-join-room">
              Join Room
            </Button>
            <Button variant="outline" size="sm" onClick={nextPhase} data-testid="button-next-phase">
              Next Phase
            </Button>
            <Button variant="outline" size="sm" data-testid="button-add-bots">
              Add 3 Bots
            </Button>
            <Button variant="outline" size="sm" data-testid="button-deal-6">
              Deal 6
            </Button>
            <Button variant="outline" size="sm" data-testid="button-reset-match">
              Reset Match
            </Button>
            <Button variant="outline" size="sm" data-testid="button-ai-step">
              AI Step
            </Button>
            <Button variant="outline" size="sm" data-testid="button-toggle-sandbox">
              Toggle Sandbox
            </Button>
            <Button variant="outline" size="sm" data-testid="button-start-tutorial">
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
                  <Button key={type} variant="outline" size="sm" className="h-7 text-xs" data-testid={`filter-type-${type.toLowerCase()}`}>
                    {type}
                  </Button>
                ))}
              </div>
            </div>
            <div>
              <p className="text-xs text-muted-foreground mb-1">Rarity</p>
              <div className="flex gap-1">
                {["All", "Low", "Mid", "Rare"].map((rarity) => (
                  <Button key={rarity} variant="outline" size="sm" className="h-7 text-xs" data-testid={`filter-rarity-${rarity.toLowerCase()}`}>
                    {rarity}
                  </Button>
                ))}
              </div>
            </div>
          </div>
          <div className="flex gap-2 items-center">
            <span className="text-sm text-muted-foreground">Zoom:</span>
            <input type="range" min="50" max="150" defaultValue="100" className="w-32" data-testid="slider-zoom" />
          </div>
        </div>
      </header>

      <div className="flex-1 relative">
        <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 gap-4 p-6">
          <div className="col-start-2 row-start-1 flex justify-center">
            <PlayerZone player={playersState[0]} compact onBattlefieldCardClick={(c) => setSelectedDefenders(arr => arr.find(x => x.id === c.id) ? arr.filter(x => x.id !== c.id) : [...arr, c])} selectedIds={selectedDefenders.map(x => x.id)} />
          </div>

          <div className="col-start-3 row-start-2 flex justify-end items-center">
            <PlayerZone player={playersState[1]} compact onBattlefieldCardClick={(c) => setSelectedDefenders(arr => arr.find(x => x.id === c.id) ? arr.filter(x => x.id !== c.id) : [...arr, c])} selectedIds={selectedDefenders.map(x => x.id)} />
          </div>

          <div className="col-start-1 row-start-2 flex justify-start items-center">
            <PlayerZone player={playersState[3]} compact onBattlefieldCardClick={(c) => setSelectedDefenders(arr => arr.find(x => x.id === c.id) ? arr.filter(x => x.id !== c.id) : [...arr, c])} selectedIds={selectedDefenders.map(x => x.id)} />
          </div>

          <div className="col-start-2 row-start-2 flex items-center justify-center">
            <CentralPlaza />
          </div>

          <div className="col-start-2 row-start-3 flex items-center justify-center gap-4">
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
      </div>

      <div className="border-t border-border">
        <div className="grid grid-cols-2 gap-4 p-4">
          <div>
            <p className="text-xs text-muted-foreground mb-2" data-testid="text-p4-hand-label">
              P4 Hand (6) - Deck 6
            </p>
            <div className="h-12 bg-muted/30 rounded border border-dashed border-border"></div>
          </div>
          <div>
            <p className="text-xs text-muted-foreground mb-2" data-testid="text-p3-hand-label">
              P3 Hand (6) - Deck 6
            </p>
            <HandArea
              cards={currentPlayer.hand}
              selectedCardId={selectedCard?.id}
              onCardClick={setSelectedCard}
            />
          </div>
        </div>

        <div className="px-4 pb-4 flex gap-12 justify-center">
          <Button data-testid="button-play">Play</Button>
          <Button data-testid="button-move">Move</Button>
          <Button data-testid="button-invoke">Invoke</Button>
          <Button data-testid="button-end" onClick={async () => { const g = await api<GameState>("/api/game/end-phase", { method: "POST" }); setCurrentPhase(g.phase); setPlayers(g.players); setGameOver(!!g.gameOver); setWinnerName((g.players||[]).find((p:any)=>p.id===g.winnerId)?.name); }}>End</Button>
        </div>
      </div>

      <CombatModal
        open={combatOpen}
        onClose={() => setCombatOpen(false)}
        defenders={selectedDefenders}
        allocation={allocations}
        onAllocationChange={setAllocations}
        attacker={selectedAttacker}
        defender={players[0].battlefield[0]}
      />
    
      <Dialog open={gameOver} onOpenChange={(o)=>o||setGameOver(false)}>
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
    </div>
  );
}
