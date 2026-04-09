# Kudurru Kings — Economy Implementation Spec v1.1

## Purpose

This document translates the economy doctrine into build-ready rules, formulas, thresholds, data structures, and processing logic. It is implementation-facing and should be used by engineering, UI, QA, and economy tuning.

This spec defines:
- currency objects
- earn formulas
- spend formulas
- acquisition channels by rarity
- duplicate conversion
- pity and protection systems
- faction mastery rewards
- account and season progression
- shop inventory rules
- ultra unlock rules
- transaction logging
- anti-abuse rules

This spec is authoritative for implementation unless intentionally superseded by a later economy spec.

---

## 1. Economy objects

### 1.1 Currencies
The game uses exactly two currencies:
- **Kudurru Shards**
- **Apex Sigils**

### 1.2 Apex progression items
The game uses exactly two Ultra Fragment item types:
- **Anu Fragment**
- **Adamu Fragment**

These are not currencies. They are card-specific progression items.

### 1.3 Non-currency progression gates
Ultra unlock also requires:
- account progression threshold
- mastery progression threshold

---

## 2. Supported rarity tiers

### 2.1 Standard tiers
- Common
- Uncommon
- Rare
- SuperRare
- Legendary

### 2.2 Apex tier
- Ultra

### 2.3 Upper-level cards
For economy logic, **upper-level cards** means:
- SuperRare
- Legendary
- Ultra

This definition must remain stable in implementation.

---

## 3. Acquisition channels by rarity

### Common
Channels:
- direct shard purchase
- starter decks
- faction bundles
- daily rewards
- weekly rewards
- mastery rewards
- standard reward drops

### Uncommon
Channels:
- direct shard purchase
- starter decks
- faction bundles
- daily rewards
- weekly rewards
- mastery rewards
- standard reward drops

### Rare
Channels:
- direct shard purchase
- faction bundles
- weekly rewards
- mastery rewards
- season rewards
- standard reward drops

### SuperRare
Channels:
- direct shard purchase
- high-tier faction bundles
- mastery milestones
- season milestones
- pity-protected reward drops

### Legendary
Channels:
- direct shard purchase
- long mastery milestones
- season milestones
- pity-protected high-tier drops
- limited high-end faction bundles

### Ultra
Channels:
- Apex Sigils
- matching Ultra Fragments
- progression gate completion

Ultra cards are never acquired from:
- direct shard purchase
- ordinary faction bundles
- ordinary standard drops

---

## 4. Exact earn formulas

## 4.1 Match-completion shard rewards

### Base by match result
- **Valid loss:** 40 Kudurru Shards
- **Valid win:** 65 Kudurru Shards

### Valid match rule
A match is valid for full rewards only if one of the following is true:
- the match reaches a normal victory/defeat resolution
- the opponent concedes after turn 3-equivalent progression
- a server-approved disconnect resolution is recorded after material progress

If a match ends too early for validity, grant:
- **0 match reward**
- no performance bonus
- no first-win bonus

## 4.2 Performance bonus formulas

### Combat win bonus
- +4 Shards per successful combat win
- cap: **+16**

### Capture bonus
- +6 Shards per successful capture
- cap: **+12**

### Arbitration bonus
- +6 Shards per successful Arbitration win
- cap: **+12**

### Site raid bonus
- +6 Shards per successful Site raid
- cap: **+12**

### Boss Trial bonus
- +2 Shards per Boss Trial counter gained
- cap: **+6**

### Objective bonus
- +10 Shards per completed match-side objective
- cap: **+20**

### Total performance cap
Maximum performance bonus per match:
- **+55**

## 4.3 Full per-match shard caps
- **Loss total cap:** 120 Shards
- **Win total cap:** 150 Shards

## 4.4 First win of day
- **+100 Kudurru Shards**
- only once per daily reset

## 4.5 Daily quests
- 3 daily quests per reset
- reward per quest: **60 Kudurru Shards**
- full-clear bonus: **40 Kudurru Shards**

## 4.6 Weekly quests
- 5 weekly quests per reset
- reward per quest: **200 Kudurru Shards**
- full-clear bonus:
  - **150 Kudurru Shards**
  - **2 Apex Sigils**

---

## 5. Apex Sigil earn rules

Apex Sigils are earned from:
- seasonal milestone levels
- faction mastery capstones
- elite achievement chains
- apex pity progress
- apex vault milestone claims
- controlled event rewards

### Routine earn restriction
Routine daily structure must not produce more than:
- **1 Apex Sigil per 24-hour window**

This does not limit:
- season milestone claims
- mastery capstones
- elite achievement payouts
- explicitly flagged event payouts

---

## 6. Faction mastery implementation

## 6.1 Factions
Mastery tracks exist for:
- Borderstone Guild
- Floodborn Pact
- Skyloom Temple
- Underwell Keepers
- Fateforge

## 6.2 Track length
Each faction mastery track has:
- **20 levels**

## 6.3 Faction mastery XP gain
- Win with faction: **20 XP**
- Loss with faction: **12 XP**
- Faction objective completion: **+8 XP**
- Faction objective XP cap per match: **+16 XP**

## 6.4 XP requirements
- Levels 1–5: 100 XP each
- Levels 6–10: 150 XP each
- Levels 11–15: 225 XP each
- Levels 16–20: 325 XP each

## 6.5 Reward table
Per faction:
- Levels 1, 3, 5, 7, 9, 11, 13, 15, 17, 19:
  - **120 Shards**
- Levels 2, 6, 10, 14, 18:
  - **1 faction card reward**
- Levels 4, 8, 12, 16:
  - **1 cosmetic/profile reward**
- Level 20:
  - **3 Apex Sigils**
  - **1 high-tier faction reward**

---

## 7. Account progression

## 7.1 Account XP gain
- Win: **25 XP**
- Loss: **15 XP**
- Daily quest completion: **20 XP**
- Weekly quest completion: **50 XP**

## 7.2 Account XP thresholds
- Levels 1–10: 100 XP each
- Levels 11–25: 150 XP each
- Levels 26–50: 225 XP each

## 7.3 Ultra account gate
Minimum account requirement for Ultra unlock:
- **Account Level 25**

---

## 8. Season progression

## 8.1 Season track length
- **50 levels**

## 8.2 XP requirement per level
- **100 season XP per level**

## 8.3 Season XP gain
- Win: **12**
- Loss: **8**
- Daily quest completion: **10**
- Weekly quest completion: **25**

## 8.4 Apex Sigil season milestone table
- Level 10: +1 Apex Sigil
- Level 20: +1 Apex Sigil
- Level 30: +2 Apex Sigils
- Level 40: +2 Apex Sigils
- Level 50: +3 Apex Sigils

Total:
- **9 Apex Sigils per full season track**

---

## 9. Starter decks and deck slots

## 9.1 Free starting access
Players start with:
- **1 free starter deck choice**
- **3 free deck slots**

## 9.2 Starter deck price
Each additional starter deck unlock:
- **500 Kudurru Shards**

## 9.3 Deck slot prices
- Slot 4: 250 Shards
- Slot 5: 350 Shards
- Slot 6: 500 Shards
- Slot 7: 700 Shards
- Slot 8: 1000 Shards

Launch hard cap:
- **8 deck slots**

## 9.4 Deck editing rule
Editing decks costs:
- **0 currency**

Only card acquisition, deck unlocks, and slot unlocks spend currency.

---

## 10. Direct purchase prices by rarity

- Common: **50 Shards**
- Uncommon: **100 Shards**
- Rare: **250 Shards**
- SuperRare: **700 Shards**
- Legendary: **1800 Shards**

Ultra:
- not purchasable with Kudurru Shards

---

## 11. Bundle structure

## 11.1 Standard faction bundle
Price:
- **600 Shards**

Contents:
- 3 Common
- 2 Uncommon
- 1 Rare

## 11.2 High-tier faction bundle
Price:
- **2200 Shards**

Contents:
- 3 Rare
- 1 SuperRare
- 20% Legendary chance
- eligible for pity tracking

---

## 12. Duplicate conversion tables

## 12.1 Standard duplicates
If a player receives a duplicate of an already-maxed standard card, grant:

- Common duplicate: **20 Shards**
- Uncommon duplicate: **40 Shards**
- Rare duplicate: **110 Shards**
- SuperRare duplicate: **300 Shards**
- Legendary duplicate: **800 Shards**

## 12.2 Ultra duplicate compensation
If a player receives an already-owned Ultra reward equivalent:
- **2 Apex Sigils**
- **8 matching Ultra Fragments**

No Shards are granted.

---

## 13. Standard pity system

## 13.1 SuperRare pity
Track high-tier bundle failures.

If the player opens **12** eligible high-tier bundle results without receiving SuperRare-or-better:
- next eligible high-tier result is guaranteed **SuperRare or better**

## 13.2 Legendary pity
If the player opens **25** eligible high-tier bundle results without receiving Legendary:
- next eligible high-tier result is guaranteed **Legendary**

## 13.3 Reset rule
A pity counter resets only when the guaranteed-or-better tier is actually awarded.

---

## 14. Ultra progression implementation

## 14.1 The only Ultra cards
- **Anu**
- **Adamu**

## 14.2 Ultra fragment types
- **Anu Fragment**
- **Adamu Fragment**

## 14.3 Ultra unlock requirements

### Anu unlock
Requires:
- **10 Apex Sigils**
- **40 Anu Fragments**
- **Account Level 25**
- **At least one faction mastery track at Level 20**

### Adamu unlock
Requires:
- **10 Apex Sigils**
- **40 Adamu Fragments**
- **Account Level 25**
- **At least one faction mastery track at Level 20**

## 14.4 Ultra Fragment sources
Fragments come from:
- season milestone claims
- elite achievement chains
- apex vault milestones
- apex pity conversion
- special event milestones

## 14.5 Fragment grant sizes
- Small fragment reward: **2**
- Medium fragment reward: **5**
- Large fragment reward: **10**

## 14.6 Apex pity rule
If the player completes an apex milestone cycle without receiving the targeted Ultra Fragment reward:
- grant **+3 matching Ultra Fragments**
- grant **+1 Apex Sigil**

This ensures visible progress.

---

## 15. Shop implementation

## 15.1 Standard shop tabs
Launch tabs:
- Starter Decks
- Cards
- Faction Bundles
- Deck Slots

## 15.2 Apex vault tabs
Launch tabs:
- Apex Progress
- Ultra Fragments
- Milestone Claims

## 15.3 Refresh cadence
- Direct card inventory: always available
- Standard bundles: always available
- High-tier bundles: always available
- Cosmetic rotating slot: every 7 days
- Apex vault rotating offers: every 14 days

## 15.4 Purchase limits
- Starter decks: one-time unlock
- Deck slots: one-time unlock per slot
- Direct card purchases: unlimited if still missing or valid under collection rules
- Apex fragment purchase: max **2 per fragment type per 14-day cycle**

---

## 16. Daily and weekly quest pools

## 16.1 Daily quest reward table
Examples:
- Win 1 Arbitration → 60 Shards
- Perform 2 captures → 60 Shards
- Gain 3 Trial counters total → 60 Shards
- Complete 3 matches → 60 Shards
- Win 1 match with rotating faction → 60 Shards

## 16.2 Weekly quest reward table
Examples:
- Win 8 matches → 200 Shards
- Complete 10 captures → 200 Shards
- Win 5 Arbitrations → 200 Shards
- Gain 12 Boss Trial counters total → 200 Shards
- Complete 20 matches → 200 Shards

---

## 17. Anti-abuse rules

## 17.1 Match farming
Do not grant full match rewards if:
- the match ends before turn 3-equivalent progression through voluntary early concession
- collusion or repetitive farm pattern is detected
- a reward repetition threshold triggers anti-abuse rules

## 17.2 Performance bonus integrity
Performance bonuses must obey the per-match caps in Section 4.

## 17.3 Apex protection
Apex Sigils must not become ordinary daily filler. Daily routine Apex income is capped as defined in Section 5.

---

## 18. Economy processing rules

## 18.1 On match completion
1. validate match state
2. compute base result reward
3. compute capped performance bonus
4. grant Shards
5. grant first-win bonus if eligible
6. update quest progress
7. update mastery XP
8. update account XP
9. update season XP
10. write transaction records

## 18.2 On duplicate acquisition
1. detect card rarity
2. check owned-count/maxed rule
3. compute duplicate conversion
4. grant currency or fragments
5. update pity state if relevant
6. write transaction records

## 18.3 On Ultra unlock
1. validate required Apex Sigils
2. validate matching Ultra Fragments
3. validate account level
4. validate mastery threshold
5. spend resources
6. unlock Ultra card
7. write transaction records

---

## 19. Economy transaction schema

Every economy transaction record must include:
- `player_id`
- `transaction_type`
- `currency_type`
- `amount`
- `source`
- `card_id`
- `rarity`
- `faction`
- `timestamp`
- `pre_balance`
- `post_balance`

### Supported transaction types
- match_reward
- quest_reward
- mastery_reward
- season_reward
- duplicate_conversion
- card_purchase
- starter_deck_unlock
- deck_slot_unlock
- apex_progress
- ultra_unlock

---

## 20. Build-ready completion rule

The economy is implementation-ready when:
- reward amounts are explicit
- acquisition channels are explicit
- duplicate conversions are explicit
- pity rules are explicit
- Ultra unlock math is explicit
- mastery and shop tables are explicit
- no reward path contradicts rarity doctrine
