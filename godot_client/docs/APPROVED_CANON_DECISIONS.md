# Approved canon decisions

Latest explicit user decisions override the operative Shipping Rules for the specific issue decided. Private EOE references remain outside this repository. Production CLOSED.

## C10 — End-income ready-unit ties (2026-10-21)

Question: when multiple players tie for the highest positive ready-combat-unit count, should all tied leaders gain +1 Sinew, or none? User decision: **none**.

Shipping Rules 13.1 therefore awards its conditional +1 Sinew only to a unique leader. A tied leader receives zero Sinew from that condition. Shipping 13.4 is unchanged: if the player earns none of the conditional End resources, the normal +1 Sinew fallback still applies. Receiving Sigil or Oath prevents that fallback; a tie does not cancel those independently earned resources.

Scope: this settles the positive-count ready-unit tie question only. It does not certify Warfield Ascendancy, alter objective-control ties, change player order, add a faction bonus, settle Stagger or Bind/Capture, or promote a development candidate to release.

Implementation already matches this decision: `scripts/match_integrator.gd::_unique_leader` and `_summary_income`. Existing `tests/test_four_seat_match.gd` checks tied ready counts with independently earned Oath, unique-leader income and 3/4-seat integration. No executable behavior or source card text needs changing. Uploaded authority files remain unchanged; this dated approval is the explicit clarification overlay.

Verification after recording C10: full Linux Godot 4.7.2 gate passed all 67 commands, 40 suites / 7,379 assertions / 0 failures and 50 Python cases, including the 165-assertion multi-seat suite. No detected console errors. Scripts, tests and tools are unchanged from the Windows-verified M24 executable source `e7084277619e4bf999615d3bc3b6b681ecc5cbfe`; no new executable or Windows export is claimed.
