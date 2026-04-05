export type KKType = "Character" | "Relic" | "Pet" | "Site";
export type KKRank = "low" | "mid" | "high" | "rare";

export interface CardDef {
  id: string;
  name: string;
  type: KKType;
  emoji: string;
  rank: KKRank;
  costs: { sinew: number; sigil: number; oath: number };
  power?: number;
  armor?: number;
  text?: string;
}

const NAMES_CHAR = [
  "Canal Duelist","Storm Scribe","River Saboteur","Kudurru Notary","Temple Sentinel","Bronze Charioteer",
  "Harbor Ranger","Clay Tablet Thief","Moon Vizier","Sand Viper Tamer","Lamassu Adept","Astral Harpooner",
  "Grain Quartermaster","Obsidian Porter","Ziggurat Custodian","Ashen Shieldbearer","Lotus Navigator",
  "Scorpion Warden","Sunlit Engraver","Euphrates Diver","Levée Overseer","Lion Standard Bearer",
  "Ishtar’s Envoy","Boundary Stone Jurist","Anzu Wingbreaker","Slingmaker Savant","Star-Chart Reader",
  "Floodgate Keeper","Reed Boat Raider","Gilded Hammerer","Omen Interpreter","Silt Breaker","Cedar Guard",
  "Mask of Humbaba","Anunnaki Vessel","Gate of Enlil Watch","Gears of Eridu","Uruk Bricklayer"
];

const EMO = ["🗡️","📜","🛶","📏","🛡️","🚩","⚙️","🏺","🐍","🪬","🪽","🌙","🧱","🌾","🌊","🔥","🗿","🔱","🦁","🦅","🐂","🧭","🪓","⛓️","🧿","🌀","🜲","🔮","🏹","⚖️","🌪️","🗻","🪵","🔱","🚪","⚙️","🧱"];
const RANKS: KKRank[] = ["low","mid","high","rare"];

function rngInt(min:number,max:number){ return Math.floor(Math.random()*(max-min+1))+min; }

function mkChars(): CardDef[] {
  const out: CardDef[] = [];
  for (let i=0;i<NAMES_CHAR.length;i++){
    const name = NAMES_CHAR[i];
    out.push({
      id: `C${i}`,
      name,
      type: "Character",
      emoji: EMO[i%EMO.length],
      rank: RANKS[i%RANKS.length],
      costs: { sinew: rngInt(0,2), sigil: rngInt(0,2), oath: rngInt(0,2) },
      power: rngInt(1,5),
      armor: rngInt(0,2),
      text: "On battle, +1 if you tested your highest axis this turn."
    });
  }
  return out;
}

function mkRelics(): CardDef[] {
  const base = [
    ["Anchor of Eridu","⚓"],["Boundary Seal","🔷"],["Eye of Anu","👁️"],["Lion Signet","🦁"],
    ["Tablet of Stars","🪬"],["Lamassu Idol","🪽"],["Cedar Torque","🪵"],["Gilded Stylus","✒️"],
    ["Oath Circlet","🪙"],["Floodgate Key","🔑"],["Astral Compass","🧭"],["Ziggurat Keystone","🧱"]
  ];
  return base.map((b,i)=>({
    id:`R${i}`, name:b[0], type:"Relic", emoji:b[1], rank:RANKS[i%RANKS.length],
    costs:{sinew:rngInt(0,1), sigil:rngInt(1,2), oath:rngInt(0,1)},
    text: "Attach: bearer gains +1 on Oath tests; enemy suffers −1 on Veil when engaged."
  }));
}

function mkPets(): CardDef[] {
  const base = [
    ["Lion of Ishtar","🦁"],["Desert Falcon","🦅"],["River Turtle","🐢"],["Marsh Hound","🐺"],
    ["Scarab Skitter","🪲"],["Ibex Jumper","🐐"],["Palace Cat","🐈"],["Osprey Scout","🦅"]
  ];
  return base.map((b,i)=>({
    id:`P${i}`, name:b[0], type:"Pet", emoji:b[1], rank:RANKS[(i+1)%RANKS.length],
    costs:{sinew:rngInt(0,1), sigil:rngInt(0,1), oath:rngInt(0,1)},
    text:"While accompanying: +1 on Wind or Eye tests (random) this battle."
  }));
}

function mkSites(): CardDef[] {
  const base = [
    ["Warfield","⛳"],["Lotus Harbor","⚓"],["Copper Foundry","🏭"],["Ziggurat Terrace","🏛️"],
    ["Flooded Canal","🌊"],["Moon Observatory","🌙"],["Cedar Yard","🪵"],["Anunnaki Gate","🚪"]
  ];
  return base.map((b,i)=>({
    id:`S${i}`, name:b[0], type:"Site", emoji:b[1], rank:RANKS[i%RANKS.length],
    costs:{sinew:0, sigil:0, oath:0}, text:"Once per turn: gain +1 to one chosen axis test."
  }));
}

export const TEST_LIBRARY: CardDef[] = [
  ...mkChars(), ...mkRelics(), ...mkPets(), ...mkSites()
];