# M25 network and collection boundary hardening

Baseline: `45999124d5d6a19d539efe8c7c66734ea4dec290`. Production CLOSED.

The existing localhost host retains its 127.0.0.1 bind, server-derived seats, owner-only decisions, session/recovery credentials and private projections. No internet deployment, new authentication provider, collection issuer or capture policy is enabled.

TCP framing now retains raw bytes until a complete newline-delimited frame exists. This preserves multibyte UTF-8 across arbitrary TCP packet boundaries. The pending buffer has an actual 16,384-byte ceiling, and each peer dispatches at most eight messages per host frame. Remaining complete frames drain on subsequent frames even without newly arriving bytes. Invalid UTF-8 is rejected before decoding, including overlong sequences, surrogate encodings and out-of-range Unicode values. These are bounded localhost candidate protections, not production transport certification.

The server-side collection ledger validates receipt object and field types before using dictionary/set/SQL operations. Malformed authority signatures, including non-ASCII strings, fail with LedgerError instead of escaping as Python TypeError. Signed malformed receipt fields cannot reach a grant transaction. Existing canonical HMAC verification, idempotent event grants, three distinct Boss axes and preservation of the original owner's collection remain unchanged. A certified live match issuer, account authentication and policy approval remain absent.

Focused validation on Linux Godot 4.7.2: framing 33 assertions / 0 failures; live TCP combat 65/0; owner reconnect 47/0; deck lobby 52/0. Python collection ledger: 8 test cases passed, including concurrent duplicate submission and malformed receipt no-grant checks. No console errors detected in those runs. New framing suite must be included in the integration quality gate before committing. Full/native gates and exports are integration responsibilities; none is claimed by this lane.

The actual client now uses the same byte-first framing and strict UTF-8 validator in the reverse direction, including an eight-message dispatch budget and queued-frame draining. The framing suite exercises server-to-client multibyte fragmentation, queued batches and malformed encoding over a real controlled local TCP peer.

Residual transport limits: the 16,384-byte limit is an aggregate pending-input ceiling, not merely a per-JSON-frame limit. A coalesced batch exceeding it disconnects even if individual messages are valid; this is deliberate fail-closed candidate behavior, not a certified high-throughput framing protocol. Dispatch budgets bound input work, but outbound `put_data` remains synchronous and has no explicit bounded send queue, rate limiter or slow-reader backpressure policy. Those protections and realistic WAN/slow-peer load testing remain production blockers.
