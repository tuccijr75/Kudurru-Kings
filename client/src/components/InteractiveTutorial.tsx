import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card as CardType, Phase } from "@shared/schema";

interface TutorialStep {
  id: string;
  title: string;
  description: string;
  targetButton?: string;
  condition?: (state: TutorialState) => boolean;
  highlight?: string[];
}

interface TutorialState {
  phase: Phase;
  handSize: number;
  battlefieldSize: number;
  selectedCard?: CardType;
}

const tutorialSteps: TutorialStep[] = [
  {
    id: "welcome",
    title: "Welcome to Kudurru Kings",
    description: "You're South Gate (bottom player). Your goal is to reduce opponents' Marks to 0. Let's learn by playing!",
    targetButton: "button-deal-6",
  },
  {
    id: "deal-cards",
    title: "Get Some Cards",
    description: "Click the 'Deal 6' button at the top to add cards to your hand.",
    targetButton: "button-deal-6",
    condition: (state) => state.handSize > 0,
  },
  {
    id: "select-card",
    title: "Select a Card",
    description: "Click on any card in your hand (bottom section) to select it. You'll see it highlight with a border.",
    condition: (state) => state.selectedCard !== undefined,
  },
  {
    id: "check-cost",
    title: "Understanding Costs",
    description: "Look at the top-left of your selected card. Those colored circles show the cost (Sinew=red, Sigil=blue, Oath=yellow). Check if you have enough resources in your player info.",
  },
  {
    id: "play-card",
    title: "Play Your Card",
    description: "With a card selected, click the 'Play' button at the bottom. This puts the card onto your battlefield.",
    targetButton: "button-play",
    condition: (state) => state.battlefieldSize > 0,
  },
  {
    id: "understand-heat",
    title: "Newly Played Cards",
    description: "Cards just played have 'heat' - they can't attack this turn. They need to cool down first. This prevents instant attacks.",
  },
  {
    id: "advance-phase",
    title: "Move to Battle Phase",
    description: "Click 'Next Phase' twice to reach the Battle phase (yellow indicator). We're currently in Main phase.",
    targetButton: "button-next-phase",
    condition: (state) => state.phase === "Battle",
  },
  {
    id: "select-attacker",
    title: "Choose Your Attacker",
    description: "Click on a creature in YOUR battlefield (South Gate area). If it has heat, it can't attack yet - click 'End' a few times to pass turns.",
  },
  {
    id: "start-combat",
    title: "Declare Attack",
    description: "With an attacker selected, click 'Start Combat'. You can attack directly (damage to Marks) or your opponent can block with their creatures.",
    targetButton: "button-open-analyzer",
  },
  {
    id: "end-turn",
    title: "End Your Turn",
    description: "Click 'End' to finish your Battle phase. Click 'End' again to finish your End phase and pass to the next player.",
    targetButton: "button-end",
  },
  {
    id: "complete",
    title: "Tutorial Complete!",
    description: "You now know the basics! Try playing a full round. Use 'Reset Match' anytime to restart. Combat keywords: Taunt (must block), First Strike (hits first).",
  },
];

interface InteractiveTutorialProps {
  phase: Phase;
  handSize: number;
  battlefieldSize: number;
  selectedCard?: CardType;
  onComplete: () => void;
  enabled: boolean;
}

export function InteractiveTutorial({
  phase,
  handSize,
  battlefieldSize,
  selectedCard,
  onComplete,
  enabled,
}: InteractiveTutorialProps) {
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [isMinimized, setIsMinimized] = useState(false);

  const currentStep = tutorialSteps[currentStepIndex];
  const tutorialState: TutorialState = { phase, handSize, battlefieldSize, selectedCard };

  useEffect(() => {
    if (!enabled) return;
    
    if (currentStep.condition && currentStep.condition(tutorialState)) {
      setTimeout(() => {
        if (currentStepIndex < tutorialSteps.length - 1) {
          setCurrentStepIndex(currentStepIndex + 1);
        }
      }, 1000);
    }
  }, [phase, handSize, battlefieldSize, selectedCard, currentStepIndex, enabled]);

  useEffect(() => {
    if (!enabled) return;

    if (currentStep.targetButton) {
      const element = document.querySelector(`[data-testid="${currentStep.targetButton}"]`);
      if (element) {
        element.classList.add('ring-4', 'ring-yellow-500', 'ring-offset-2');
        return () => {
          element.classList.remove('ring-4', 'ring-yellow-500', 'ring-offset-2');
        };
      }
    }
  }, [currentStep, enabled]);

  if (!enabled) return null;

  const handleNext = () => {
    if (currentStepIndex < tutorialSteps.length - 1) {
      setCurrentStepIndex(currentStepIndex + 1);
    } else {
      onComplete();
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  if (isMinimized) {
    return (
      <div className="fixed bottom-4 right-4 z-50">
        <Button onClick={() => setIsMinimized(false)} variant="default">
          Show Tutorial ({currentStepIndex + 1}/{tutorialSteps.length})
        </Button>
      </div>
    );
  }

  return (
    <div className="fixed bottom-4 right-4 z-50 w-96 bg-card border-2 border-primary rounded-lg shadow-2xl p-4">
      <div className="flex justify-between items-start mb-3">
        <div className="flex-1">
          <div className="text-xs text-muted-foreground mb-1">
            Step {currentStepIndex + 1} of {tutorialSteps.length}
          </div>
          <h3 className="font-bold text-lg">{currentStep.title}</h3>
        </div>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setIsMinimized(true)}
          className="h-6 w-6 p-0"
        >
          −
        </Button>
      </div>

      <p className="text-sm mb-4 leading-relaxed">{currentStep.description}</p>

      <div className="flex gap-2">
        <Button variant="outline" size="sm" onClick={handleSkip}>
          Skip Tutorial
        </Button>
        {!currentStep.condition && (
          <Button size="sm" onClick={handleNext}>
            {currentStepIndex === tutorialSteps.length - 1 ? "Finish" : "Next"}
          </Button>
        )}
      </div>

      {currentStep.condition && (
        <div className="mt-3 text-xs text-muted-foreground italic">
          Complete the action above to continue...
        </div>
      )}
    </div>
  );
}