> Migrated note: Retained implementation-support document migrated from migrate.zip. Values preserved as product/progression reference.

# Kudurru Kings — Economy Implementation Spec v1.0

## Purpose

This document converts the Economy & Rewards Doctrine into build-ready implementation rules. It defines:
- exact currencies
- exact earn formulas
- exact spend tables
- exact duplicate conversion values
- exact pity and apex progression rules
- exact mastery structure
- exact shop structure
- exact rarity acquisition channels
- exact implementation fields and state rules

This spec is subordinate to gameplay doctrine and economy doctrine on intent, but authoritative for implementation values unless explicitly revised.

---

## 1. Currency model

### 1.1 Currencies
The game uses exactly two progression currencies:

- **Kudurru Shards**
- **Apex Sigils**

### 1.2 Supporting progression item
Ultra acquisition also uses a non-currency item type:

- **Ultra Fragments**

Ultra Fragments are card-specific progression items, not spendable universal currency.

### 1.3 Card-specific fragment types
There are exactly two Ultra Fragment types:
- **Anu Fragment**
- **Adamu Fragment**

Fragments are not interchangeable.

---

## 2. Rarity acquisition channels

## 2.1 Standard rarity ladder
Supported non-apex tiers:
- Common
- Uncommon
- Rare
- SuperRare
- Legendary

## 2.2 Acquisition matrix by rarity

### Common
Available from:
- direct shard purchase
- starter decks
- faction bundles
- daily/weekly rewards
- match/quest reward drops
- mastery rewards

### Uncommon
Available from:
- direct shard purchase
- faction bundles
- daily/weekly rewards
- mastery rewards
- standard reward drops

### Rare
Available from:
- direct shard purchase
- faction bundles
- weekly rewards
- mastery rewards
- standard reward drops
- season track rewards

### SuperRare
Available from:
- direct shard purchase at high shard cost
- mastery milestones
- season track milestones
- faction bundles with controlled limits
- reward drops with protection

### Legendary
Available from:
- direct shard purchase at very high shard cost
- long mastery milestones
- season track milestones
- high-tier reward drops with pity protection
- limited faction progression bundles

### Ultra
Available from:
- **Apex Sigils**
- **Ultra Fragments**
- **progression gate completion**

Ultra cards are **not** available from:
- direct shard purchase
- ordinary standard drops
- standard faction bundles
- ordinary shop inventory

---

## 3. Live data model for economy

Each player account must track:

- `kudurru_shards`
- `apex_sigils`
- `anu_fragments`
- `adamu_fragments`
- `account_level`
- `season_level`
- `faction_mastery_borderstone`
- `faction_mastery_floodborn`
- `faction_mastery_skyloom`
- `faction_mastery_underwell`
- `faction_mastery_fateforge`
- `owned_cards`
- `owned_deck_slots`
- `daily_first_win_claimed`
- `daily_quest_progress`
- `weekly_quest_progress`
- `standard_pity_counter_superrare`
- `standard_pity_counter_legendary`
- `ultra_progress_anu`
- `ultra_progress_adamu`

---

## 4. Reward formulas

## 4.1 Match rewards

### Base payout by result
Every completed match grants Kudurru Shards:

- **Loss:** 40 Shards
- **Win:** 65 Shards

### Completion rule
A match counts as completed only if:
- it reaches a valid end state, or
- the opponent concedes after turn 3 equivalent progression, or
- the player remains connected until a valid loss state is recorded

This prevents early abuse.

### 4.2 Performance bonuses
Additive Kudurru Shard bonuses per match:

- +4 per successful combat win, cap **+16**
- +6 per successful capture, cap **+12**
- +6 per successful Arbitration win, cap **+12**
- +6 per successful Site raid, cap **+12**
- +2 per Boss Trial counter gained, cap **+6**
- +10 objective completion bonus, cap **+20**

### 4.3 Per-match hard cap
Maximum Kudurru Shards from a single match:
- **120 on a loss**
- **150 on a win**

This includes all performance bonuses.

### 4.4 First win of day
The first valid win each day grants:
- **+100 Kudurru Shards**

### 4.5 Daily quest rewards
Each daily quest grants:
- **60 Kudurru Shards**

Daily quest count:
- **3 daily quests**

Daily full-clear bonus:
- **+40 Kudurru Shards**

### 4.6 Weekly rewards
Each weekly quest grants:
- **200 Kudurru Shards**

Weekly quest count:
- **5 weekly quests**

Weekly full-clear bonus:
- **+2 Apex Sigils**
- **+150 Kudurru Shards**

---

## 5. Mastery structure

## 5.1 Faction mastery tracks
Each of the 5 core factions has a mastery track.

Each faction mastery track has:
- **20 levels**

### 5.2 Faction mastery XP
Faction mastery XP gain:
- **Win with faction:** 20 XP
- **Loss with faction:** 12 XP
- **Complete faction objective in match:** +8 XP, cap +16 per match

### 5.3 XP requirement by level
For faction mastery levels 1–20:

- Levels 1–5: 100 XP each
- Levels 6–10: 150 XP each
- Levels 11–15: 225 XP each
- Levels 16–20: 325 XP each

### 5.4 Faction mastery rewards
Per faction mastery track:
- Levels 1, 3, 5, 7, 9, 11, 13, 15, 17, 19:
  - **+120 Kudurru Shards**
- Levels 2, 6, 10, 14, 18:
  - **1 faction card reward**
- Levels 4, 8, 12, 16:
  - **cosmetic or profile reward slot**
- Level 20:
  - **+3 Apex Sigils**
  - **1 high-tier faction card reward**

---

## 6. Account progression and season track

## 6.1 Account level
Account XP gain:
- **Win:** 25 XP
- **Loss:** 15 XP
- **Daily quest completion:** 20 XP
- **Weekly quest completion:** 50 XP

### 6.2 Account level thresholds
- Levels 1–10: 100 XP each
- Levels 11–25: 150 XP each
- Levels 26–50: 225 XP each

### 6.3 Account progression gate for Ultra
Ultra unlock requires:
- **Account Level 25 minimum**

## 6.4 Season track
Season track has:
- **50 levels**

Each level requires:
- **100 season XP**

Season XP sources:
- **Win:** 12
- **Loss:** 8
- **Daily quest completion:** 10
- **Weekly quest completion:** 25

### 6.5 Apex Sigil season milestones
Season levels granting Apex Sigils:
- Level 10: +1
- Level 20: +1
- Level 30: +2
- Level 40: +2
- Level 50: +3

Total seasonal Apex Sigils:
- **9**

---

## 7. Starter decks and deck slots

## 7.1 Starter decks
Each core faction has one starter deck.

Starter deck unlock price:
- **500 Kudurru Shards**

### 7.2 Initial free access
Players start with:
- **1 free starter deck choice**
- **3 free deck slots**

### 7.3 Additional deck slots
Deck slot prices:
- Slot 4: 250 Shards
- Slot 5: 350 Shards
- Slot 6: 500 Shards
- Slot 7: 700 Shards
- Slot 8: 1000 Shards

Hard cap at launch:
- **8 deck slots**

### 7.4 Deck editing rule
Deck editing does **not** cost currency.
Only unlocking cards, decks, and slots costs currency.

---

## 8. Direct card crafting / purchase prices

## 8.1 Direct purchase prices by rarity
- Common: **50 Shards**
- Uncommon: **100 Shards**
- Rare: **250 Shards**
- SuperRare: **700 Shards**
- Legendary: **1800 Shards**

Ultra cards are not directly purchasable with Shards.

## 8.2 Faction bundle prices
Faction bundle (standard small):
- **600 Shards**

Faction bundle contents:
- 3 Common
- 2 Uncommon
- 1 Rare

Faction bundle (high-tier):
- **2200 Shards**

High-tier faction bundle contents:
- 3 Rare
- 1 SuperRare
- 20% chance of Legendary
- pity-tracked for Legendary after repeated failures

---

## 9. Duplicate conversion rules

## 9.1 Standard duplicate shard values
When a player receives a duplicate owned card, convert it into Kudurru Shards:

- Common duplicate: **20 Shards**
- Uncommon duplicate: **40 Shards**
- Rare duplicate: **110 Shards**
- SuperRare duplicate: **300 Shards**
- Legendary duplicate: **800 Shards**

### 9.2 Ultra duplicate compensation
Ultra duplicate compensation converts to:
- **2 Apex Sigils**
- **8 matching Ultra Fragments**

No Kudurru Shards are granted for Ultra duplicates.

---

## 10. Standard pity protection

## 10.1 High-tier drop pity counters
Use two pity counters:

- `standard_pity_counter_superrare`
- `standard_pity_counter_legendary`

### 10.2 SuperRare pity
After **12** high-tier bundle rewards without a SuperRare-or-better result:
- next eligible high-tier drop is guaranteed **SuperRare or better**

### 10.3 Legendary pity
After **25** high-tier bundle rewards without a Legendary result:
- next eligible high-tier drop is guaranteed **Legendary**

### 10.4 Counter reset rule
A pity counter resets only when the guaranteed-or-better tier is actually received.

---

## 11. Ultra acquisition implementation

## 11.1 Ultra cards
The only Ultra cards are:
- **Anu**
- **Adamu**

## 11.2 Ultra unlock requirements
To unlock an Ultra card, the player must have:

### Anu
- **10 Apex Sigils**
- **40 Anu Fragments**
- **Account Level 25**
- **At least one faction mastery track at level 20**

### Adamu
- **10 Apex Sigils**
- **40 Adamu Fragments**
- **Account Level 25**
- **At least one faction mastery track at level 20**

## 11.3 Ultra Fragment earn sources
Ultra Fragments are earned from:
- season milestone claims
- elite achievement chains
- apex vault milestones
- apex pity conversion
- special event milestone rewards

### 11.4 Fragment milestone values
Default fragment grants:
- small fragment reward: **2 fragments**
- medium fragment reward: **5 fragments**
- large fragment reward: **10 fragments**

## 11.5 Apex pity
If a player completes an apex milestone cycle without receiving the targeted Ultra Fragment reward:
- they gain **+3 matching Ultra Fragments**
- they gain **+1 Apex Sigil**

This ensures visible long-term progress.

---

## 12. Shop structure

## 12.1 Standard shop tabs
Launch standard shop tabs:
- Starter Decks
- Cards
- Faction Bundles
- Deck Slots

## 12.2 Apex vault
Launch apex vault tabs:
- Apex Progress
- Ultra Fragments
- Milestone Claims

## 12.3 Refresh rules
- Direct card purchase inventory: always available
- Standard faction bundles: always available
- High-tier faction bundles: always available
- Cosmetic/optional rotating slot: refresh every 7 days
- Apex vault offers: refresh every 14 days where rotation is used

## 12.4 Purchase limits
- Starter decks: one-time unlock
- Deck slots: one-time unlock per slot
- Direct cards: unlimited if still missing or intentionally re-purchasable under collection rules
- Apex vault fragment purchase: max **2 purchases per 14-day cycle** per fragment type

---

## 13. Daily and weekly quest pools

## 13.1 Daily quest examples
Daily quest objective values:
- Win 1 Arbitration → 60 Shards
- Perform 2 captures → 60 Shards
- Gain 3 Trial counters total → 60 Shards
- Complete 3 matches → 60 Shards
- Win 1 match with rotating faction → 60 Shards

## 13.2 Weekly quest examples
Weekly quest objective values:
- Win 8 matches → 200 Shards
- Complete 10 captures → 200 Shards
- Win 5 Arbitrations → 200 Shards
- Gain 12 total Boss Trial counters → 200 Shards
- Complete 20 matches → 200 Shards

---

## 14. Upper-level card definition

For economy purposes, **upper-level cards** means:
- SuperRare
- Legendary
- Ultra

### Acquisition doctrine by upper level
- SuperRare: Shards + rewards + pity
- Legendary: Shards + milestones + stronger pity
- Ultra: Apex Sigils + Ultra Fragments + progression gate

This term should not be used ambiguously in implementation.

---

## 15. Anti-abuse rules

## 15.1 Match farming guardrails
No full match payout if:
- match ends before turn 3 equivalent progression by voluntary early concession
- repeated collusion pattern is detected
- reward repetition triggers anti-farm threshold

### 15.2 Performance bonus cap
Per-match performance bonuses are hard-capped as defined in Section 4.

### 15.3 Daily Apex Sigil cap
No more than **1 Apex Sigil** may be earned from routine daily structure in a 24-hour window outside milestone claim systems.

This preserves prestige.

---

## 16. Economy state transitions

## 16.1 On match completion
1. validate match completion
2. calculate base result payout
3. calculate capped performance bonus
4. apply quest/mastery/account/season XP
5. grant currency
6. check daily first win bonus
7. update progression counters

## 16.2 On duplicate acquisition
1. detect rarity
2. check if owned copy exceeds allowed collection rule
3. apply duplicate conversion
4. update pity state if relevant
5. write transaction log

## 16.3 On Ultra unlock
1. validate Apex Sigils
2. validate matching Ultra Fragments
3. validate account level
4. validate mastery gate
5. spend resources
6. unlock Ultra card
7. write transaction log

---

## 17. Build-facing implementation fields

Minimum economy fields per transaction record:
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

Supported transaction types:
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

## 18. Final implementation doctrine

The economy is implementation-ready only when:
- reward amounts are explicit
- acquisition channels are explicit
- duplicate conversions are explicit
- pity rules are explicit
- Ultra unlock math is explicit
- mastery and shop tables are explicit
- no currency path contradicts gameplay rarity doctrine
