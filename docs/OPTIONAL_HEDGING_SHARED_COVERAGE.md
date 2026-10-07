# Maker hedging choice and shared coverage UI

Source candidate, 2026-10-07; installation and live acceptance are separate.
The engine owns math/risk and advertises optional_hedging/shared_coverage v1.
The wallet negotiates the capability and adds a Hedging switch for new makers;
existing makers display a locked choice, including when paused. Old profiles
remain hedged. DEX-only fixed prices do not need a CEX plugin route/readiness;
public-price-only makers need their chosen CEX public reference, not API keys.
Quantity remains an explicit fixed/automatic setting, bounded by KDF funds and
budgets when there is no hedge. The form and row/details disclose unhedged
inventory exposure, fixed vs reference price and absence of compensating trades.

Shared hedge coverage reports CEX free/committed/uncommitted/missing amounts.
It is a display snapshot, never execution permission. Unavailable or stale
balances remain unavailable; exact Decimal values remain in tooltips. Older
maker UUIDs retain deterministic allocation priority; automatic quantities may
shrink through backend guards, fixed amounts require withdrawal when uncovered.
Draft/session fencing and manual paused creation/start confirmations remain.

The existing rebalance still requires paused makers for execution. Its selection
excludes makers without hedge obligations; no custom quantity/snapshot or live
rebalance execution is introduced. Engine details and limitations are documented
in MM_Engine/docs/OPTIONAL_HEDGING_SHARED_COVERAGE.md. Impeller and SDK/KDF behavior
are unchanged. Static analysis is not widget, concurrent financial or funded
acceptance; no production restart is implied by a source change.
