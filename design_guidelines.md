# Kudurru Kings - Design Guidelines

## Design Approach: Reference-Based (Dark Fantasy Gaming UI)

**Primary References:** Hearthstone, Magic: The Gathering Arena, Legends of Runeterra
**Visual Direction:** Dark fantasy aesthetic with ancient Mesopotamian influences, gold/bronze accents, rich textures

## Core Design Principles

1. **Immersive Battlefield Focus:** Central play area dominates the viewport with player zones arranged in cardinal positions
2. **Information Clarity:** Game state, resources, and card details must be immediately readable despite rich visual treatment
3. **Strategic Depth Visibility:** All combat calculations, resource pools, and card states clearly indicated through UI elements

## Color Palette

### Dark Mode (Primary)
- **Background Deep:** 220 15% 8% (dark charcoal blue)
- **Surface Elevated:** 220 12% 12% (elevated panels)
- **Surface Card:** 220 10% 15% (card backgrounds)
- **Primary Gold:** 45 90% 55% (ancient gold, borders, highlights)
- **Accent Bronze:** 30 40% 45% (secondary metallics)
- **Resource Sinew:** 0 70% 50% (red, physical)
- **Resource Sigil:** 270 80% 65% (purple, arcane)
- **Resource Oath:** 200 75% 55% (blue, command)
- **Marks Victory:** 45 95% 60% (bright gold)
- **Heat Strain:** 15 85% 55% (orange-red)
- **Text Primary:** 0 0% 95% (near white)
- **Text Secondary:** 220 10% 70% (muted gray)
- **Success:** 140 60% 50% (victory green)
- **Danger:** 0 75% 55% (defeat red)

## Typography

**Font Families:**
- **Display/Headers:** 'Cinzel Decorative', serif (fantasy, ancient feel) - via Google Fonts
- **Body/UI:** 'Inter', sans-serif (clean readability) - via Google Fonts
- **Numbers/Stats:** 'JetBrains Mono', monospace (resource counters) - via Google Fonts

**Scale:**
- Hero/Title: text-4xl to text-6xl (Cinzel)
- Section Headers: text-2xl to text-3xl (Cinzel)
- Card Titles: text-lg font-semibold (Inter)
- Body Text: text-base (Inter)
- UI Labels: text-sm (Inter)
- Stat Numbers: text-xl font-bold (JetBrains Mono)

## Layout System

**Spacing Primitives:** Tailwind units of 2, 4, 8, 12, 16 (p-2, h-8, m-4, gap-12, p-16)

**Grid Structure:**
- Battlefield: Full viewport grid with 4-player positions (top, right, bottom, left)
- Central Plaza: 40% viewport width/height, centered
- Player Zones: Positioned in corners/edges, 25% viewport allocation each
- Hand Area: Bottom dock, fixed height ~200px, horizontally scrollable
- Resource Pools: Fixed position sidebar, 100px width per pool

## Component Library

### A. Battlefield Components

**Central Plaza Card:**
- Ornate border with gold corner flourishes
- Translucent dark background (bg-opacity-80)
- Title in Cinzel with gold text
- Atmospheric background image (ancient ruins, mystical energy)

**Player Zones:**
- Each player has: Avatar, Name, Resource Counters, Marks Display
- Character cards arranged in 3-card row (battlefield units)
- Sites row below characters (global effects)
- Capture pile indicator (small card stack icon)

**Card Display:**
- Front: Corner cost pips, world/rarity chips, art area, title bar, type strip with power/armor
- Hover: Enlarge 1.2x, show full details, glow effect matching world color
- Attached items: Small icons overlaid on bottom-right (Pet), bottom-left (Relic)
- Heat counters: Orange flame icons in top-right, animated pulse
- Wounds: Red crack overlay with counter

### B. Resource Management

**Pool Counters (3 visible always):**
- Circular tokens with icon + number
- Sinew: Red muscle/fist icon
- Sigil: Purple arcane symbol
- Oath: Blue shield/banner icon
- Increment/decrement buttons on hover
- Glow effect when resources spent in combat

**Marks Display:**
- Large gold star/crown icon
- Bold number in JetBrains Mono
- Progress bar showing distance to victory (7/10/12 targets)

### C. Combat Interface

**Engagement Modal:**
- Semi-transparent overlay dimming battlefield
- Large cards for Attacker vs Defender (side-by-side)
- Test Axis Selection: 3 large buttons (Stone/Veil/Oath) with icons
- Resource Commitment: Slider 0-2 for chosen axis, shows +2/+4 bonus
- Support Selection: Clickable allied character cards
- Combat Calculator: Real-time score display showing:
  - Base Power + Boosts + Support + Synergies
  - Visual equation breakdown
- Confirm/Cancel action buttons (gold primary, gray secondary)

### D. Game Controls

**Phase Control Bar (top-right):**
- Current phase highlighted (Upkeep → Main → Battle → End)
- Next Phase button (large, gold, pulsing when available)
- Current player indicator with avatar glow

**Action Buttons (top-left cluster):**
- Join Room (multiplayer setup)
- Reset Match (confirmation required)
- AI Step (for testing/sandbox)
- Deal 6 (hand reset)
- Toggle Sandbox (dev mode switch)
- Start Tutorial (guided flow)
- Open Library (card browser)

**Hand Manager (bottom dock):**
- Horizontal scrollable card tray
- Cards tilt on hover, selected card lifts
- Drag-to-play interaction area
- Discard zone on far right (glowing red when over 9 cards)

### E. Card Browser/Library

**Grid Layout:**
- 4-column masonry on desktop, 2 on tablet, 1 on mobile
- Filter sidebar: World, Type, Rarity, Cost range
- Search bar with fuzzy matching
- Card stats preview on hover
- Click to expand full rules text

### F. Tutorial Overlay

**Step-by-Step Guidance:**
- Spotlight effect highlighting current element
- Translucent dark overlay (bg-black/80)
- Tooltip with arrow pointer, gold border
- Step counter (1/10, 2/10, etc.)
- Skip/Next navigation
- Animated arrows pointing to interactive elements

## Visual Effects & Animations

**Minimal, Strategic Use:**
- Card play: Gentle slide from hand to battlefield (300ms ease-out)
- Combat resolution: Winner card glows, loser fades/slides to capture (500ms)
- Resource spend: Coin/token fly animation to combat calculator (400ms)
- Phase transition: Subtle fade between phases (200ms)
- Heat removal: Flame icon dissolves upward on upkeep (300ms)

**NO:** Constant background animations, parallax effects, excessive particles

## Images

**Hero/Central Plaza:**
- Large atmospheric background: Ancient Mesopotamian ziggurat ruins at twilight, mystical energy swirling, 1920x1080
- Placement: Full background of central plaza card, subtle parallax on hover

**Card Art Placeholders:**
- Character cards: Portrait-oriented fantasy art (512x768)
- Sites: Landscape environmental art (768x512)
- Relics/Pets: Square item/creature art (512x512)
- Use vibrant fantasy illustrations with world-appropriate theming

**World Backgrounds:**
- Mars: Red desert, war-torn landscapes
- Earth: Lush forests, mystical groves
- Moon: Silver ethereal realms, starlight
- Nibiru: Balanced cosmic vistas, ancient technology

## Responsive Behavior

**Desktop (1920x1080+):** Full 4-player battlefield layout
**Tablet (768-1919px):** Compressed battlefield, smaller card sizes, scrollable zones
**Mobile (< 768px):** Single-column, focused on active player's view, swipe between opponent zones

## Accessibility

- All interactive elements: min 44px touch targets
- Sufficient contrast ratios (WCAG AA): Gold on dark backgrounds tested
- Keyboard navigation: Tab through all controls, Enter to activate
- Screen reader labels for all icons and game states
- Color-blind safe: Icons + text for all resource/status indicators

## Information Hierarchy

1. **Critical (Always Visible):** Current phase, active player, Marks, resources
2. **Primary (Battlefield Focus):** Character cards, combat stats, attachments
3. **Secondary (Contextual):** Hand cards, opponent details, Sites
4. **Tertiary (On-Demand):** Full card rules, tutorial steps, library browser

This design creates an immersive, strategically clear dark fantasy card game experience that honors the rich lore while maintaining competitive gameplay visibility.