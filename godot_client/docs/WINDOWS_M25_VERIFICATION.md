# M25 Windows candidate verification

Production CLOSED. Source commit: `7fd8fdd7ae7dbd208c8c29aa6e35bb3607b67904`; branch `build/m25-parallel-completion-20261021`. Integration began from M24 plus C10 at `4599912`.

Both Linux and native Windows Godot4.7.2 gates passed73 commands,42 Godot suites /7,700 assertions /0 failures, and99 Python cases, with no detected console errors. Included existing deterministic replay, source/legal deck/card conservation, ownership/private projection and defender-consent suites plus new framing, multi-seat peek/save migration and source/art/readiness adversarial tests.

The first Windows run failed because file-symlink fixtures required a Windows privilege. Commit `7fd8fdd` replaced them with real directory junction fixtures on Windows and directory symlinks on Linux; both full gates then passed without elevation or skips. Native tested index tree `6cd229f737d549879607489482f68f11d12b9ec0` exactly matched the committed export source before clean checkout/export. No game mechanics changed in this fixture correction.

Candidate: `E:\KudurruKings\Builds\KudurruKings_M25_WindowsCandidate_7fd8fdd.zip`

ZIP bytes:38,643,401. SHA256: `15020328c65130d4387177e8aa8c182259299cc56e033be1fb1cc8bfaa8a3e75`.

Native export, staged executable headless launch, ZIP CRC, branch/commit manifest, EXE/PCK sizes+SHA256, safe fresh separate extraction and extracted native EXE headless launch all passed. This is independent extraction on the same ManicsPC, not independent external tester certification. No embedded Authenticode certificate is present. Human visual acceptance, installer/update validation and production certification remain unverified.

Windows gate log: `E:\KudurruKings\m25_native_gate_commands.log`; SHA256 `77a1aff2073b92b1922219180f58e064ea4085725f348eb21f85aa336aefdd58`.

Final Linux gate SHA256: `52b02e555f49fee6fb9a1c3e9b3cdabeff01f555c69ad34d6a4d8c1b18c09529`.

Original Windows `E:\KudurruKings\repo` remained clean at M18 `caf153dcf400b0f461de6b3c9a188e84e4b89022`. Native development worktree was clean at the exported source. No WAN listener, production release, merge, signing, account rewards or private EOE publication occurred.

Detailed machine evidence is `data/m25_verification.json`; swarm ownership/change boundaries are in `M25_SWARM_INTEGRATION.md`. Supplied-art inspection is in `M25_SUPPLIED_ART_INVENTORY.md`:20generic layers, no individual card illustration inventory. None of these results certifies754-card Standard.
