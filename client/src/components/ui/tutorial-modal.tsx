import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { useState } from "react";

interface TutorialModalProps {
  open: boolean;
  onClose: () => void;
}

export function TutorialModal({ open, onClose }: TutorialModalProps) {
  const [step, setStep] = useState(0);

  const tutorials = [
    {
      title: "Welcome to Kudurru Kings",
      content: (
        <div className="space-y-4">
          <p>Kudurru Kings is a 4-player card battler. The goal is to reduce your opponents' Marks to 0.</p>
          <p className="font-semibold">Each player starts with:</p>
          <ul className="list-disc pl-6 space-y-1">
            <li>10 Marks (health)</li>
            <li>Resources: Sinew, Sigil, and Oath</li>
            <li>A hand of cards</li>
          </ul>
        </div>
      )
    },
    {
      title: "Game Phases",
      content: (
        <div className="space-y-3">
          <p>Each turn has 4 phases:</p>
          <div className="space-y-2">
            <div className="border p-2 rounded">
              <p className="font-semibold text-yellow-500">1. Upkeep</p>
              <p className="text-sm">Refresh resources, trigger upkeep effects</p>
            </div>
            <div className="border p-2 rounded">
              <p className="font-semibold text-green-500">2. Main</p>
              <p className="text-sm">Play cards from your hand to the battlefield</p>
            </div>
            <div className="border p-2 rounded">
              <p className="font-semibold text-red-500">3. Battle</p>
              <p className="text-sm">Attack with your creatures</p>
            </div>
            <div className="border p-2 rounded">
              <p className="font-semibold text-blue-500">4. End</p>
              <p className="text-sm">End your turn, pass to next player</p>
            </div>
          </div>
        </div>
      )
    },
    {
      title: "Playing Cards",
      content: (
        <div className="space-y-4">
          <p>During the Main phase:</p>
          <ol className="list-decimal pl-6 space-y-2">
            <li><strong>Click a card</strong> in your hand to select it (it will highlight)</li>
            <li>Check the card's cost in the top-left corner</li>
            <li>Make sure you have enough resources (shown in your player zone)</li>
            <li>Click the <strong>Play</strong> button</li>
            <li>The card moves from your hand to the battlefield</li>
          </ol>
          <p className="text-sm text-muted-foreground mt-4">
            Cards with a "summoning" state can't attack on the turn they're played.
          </p>
        </div>
      )
    },
    {
      title: "Combat",
      content: (
        <div className="space-y-4">
          <p>During the Battle phase:</p>
          <ol className="list-decimal pl-6 space-y-2">
            <li>Click a creature on YOUR battlefield to select it as attacker</li>
            <li>Click enemy creatures to select them as blockers (optional)</li>
            <li>Click <strong>Start Combat</strong> to resolve the attack</li>
            <li>If no blockers, damage goes to the player's Marks</li>
            <li>If blocked, creatures deal damage to each other</li>
          </ol>
          <div className="border p-2 rounded bg-muted/30 mt-4">
            <p className="text-sm"><strong>Power/Armor:</strong> The numbers on each card</p>
            <p className="text-sm">Power = damage dealt, Armor = health</p>
          </div>
        </div>
      )
    },
    {
      title: "Keywords",
      content: (
        <div className="space-y-3">
          <p>Special abilities to know:</p>
          <div className="space-y-2">
            <div className="border p-2 rounded">
              <p className="font-semibold">Taunt</p>
              <p className="text-sm">Must be blocked if able. Protects the player.</p>
            </div>
            <div className="border p-2 rounded">
              <p className="font-semibold">First Strike</p>
              <p className="text-sm">Deals damage before normal combat damage.</p>
            </div>
            <div className="border p-2 rounded">
              <p className="font-semibold">Haste</p>
              <p className="text-sm">Can attack immediately (no summoning sickness).</p>
            </div>
          </div>
        </div>
      )
    },
    {
      title: "Quick Start Guide",
      content: (
        <div className="space-y-4">
          <p className="font-semibold">Try these steps now:</p>
          <ol className="list-decimal pl-6 space-y-2">
            <li>Click <strong>Deal 6</strong> to get cards</li>
            <li>Click a card in your hand to select it</li>
            <li>Click <strong>Play</strong> to put it on the battlefield</li>
            <li>Click <strong>Next Phase</strong> twice to reach Battle phase</li>
            <li>Click your battlefield creature, then <strong>Start Combat</strong></li>
            <li>Click <strong>End</strong> to finish your turn</li>
          </ol>
          <p className="text-sm text-muted-foreground mt-4">
            Use <strong>Reset Match</strong> anytime to start over.
          </p>
        </div>
      )
    }
  ];

  const handleNext = () => {
    if (step < tutorials.length - 1) {
      setStep(step + 1);
    } else {
      onClose();
      setStep(0);
    }
  };

  const handlePrev = () => {
    if (step > 0) {
      setStep(step - 1);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(isOpen) => !isOpen && onClose()}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>{tutorials[step].title}</DialogTitle>
        </DialogHeader>
        <div className="py-4 max-h-96 overflow-y-auto">
          {tutorials[step].content}
        </div>
        <DialogFooter className="flex justify-between items-center">
          <div className="text-sm text-muted-foreground">
            Step {step + 1} of {tutorials.length}
          </div>
          <div className="flex gap-2">
            <Button 
              variant="outline" 
              onClick={handlePrev} 
              disabled={step === 0}
            >
              Previous
            </Button>
            <Button onClick={handleNext}>
              {step === tutorials.length - 1 ? "Start Playing" : "Next"}
            </Button>
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}