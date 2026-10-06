> Historical layout QA for the initial preview screen. The rebalance read-only
> statement below describes that fixture revision; current rebalance behavior is
> documented in docs/GUI_AUDIT_HARDENING.md and docs/P2PIRATE_MM_ENGINE.md.

# Trading engine layout QA

- Source: /home/rnz/Documenti/MMEngine_1.jpg (1171 × 1111).
- Implementation: ../../artifacts/p2pirate/2026-10-03-mm-preview/design/dashboard.png (1171 × 1111, density 1).
- Evidence: native Linux Flutter test in Xvfb, isolated profile. Representative order/balance fixtures are test-only; the production page reads authenticated engine APIs.
- State: preview, two maker orders, MEXC selected. Compared the full component surface and the maker/CEX regions.
- Layout: header separator/status banner, separated left/right global controls, maker table, whitespace, CEX selector and balance table preserve the reference hierarchy.
- Interaction checks: Gate selector dispatches the expected venue; no layout overflow or Flutter exceptions. Production page retains Refresh and Check updates in its header.
- Comparison history: initial test capture used Ahem fonts; loaded Manrope and verified the native renderer. Moved New Maker Order to the right and applied gold primary buttons; final screenshot confirms both changes.
- Remaining P3: app typography and row spacing retain the wallet style rather than the drawing's monospaced text. Rebalance area is deliberately read-only pending its full workflow; no transfers are represented as implemented.
- final result: passed
