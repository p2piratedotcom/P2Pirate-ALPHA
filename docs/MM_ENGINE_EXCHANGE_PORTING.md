# Exchange boundary and preview improvements

MM_Engine owns exchange configuration and adapters in its separate repository.
The wallet remains a local API client and does not hold exchange sizing or signing
logic. Preview can now read Spot balances without enabling live trading; API
credentials for the selected venue are required, and invalid keys or expired reads
remain errors. Saving leaves the strategy paused.

The strategy confirmation renders KDF sold amount, quote price with units and
exchange hedge legs rather than raw JSON. Engine errors preserve the HTTP status
in a typed exception while displaying the actionable message without `Bad state`.
Gate-only credentials can enable live mode; the engine independently validates
permissions, coverage and all publication controls.

The paired MM_Engine candidate must be installed to exercise the preview fix.
An older immutable engine release still contains the original missing-lease check.
See the engine repository `docs/EXCHANGE_ARCHITECTURE.md` for configuration and
adapter responsibilities and its compatibility limits.

## Numbered maker order workflow (2026-10-03)

The dashboard numbers orders by the engine's persistent SQLite creation number,
including configurations saved before this change. Internal identifiers remain
unchanged and archived rows retain their number. Numbering survives database
reopening and SQLite VACUUM. Paused rows derive sold/bought
tickers and automatic/fixed modes directly from the saved specification. Fixed
BUY prices use bought-per-sold units, matching the published KDF order.

Pause uses the engine's authenticated strategy pause endpoint. Modify is offered
only after publication has been withdrawn and the strategy is disabled, without
unresolved writes or review states. The form preserves risk settings and uses
`/v1/strategies/update`, so consumption history is retained. Preview and saving do
not resume publication. Routing (market, CEX, assets and direction) is immutable
for an existing configuration; changing it requires a new order. Details shows
parameters and state without making requests that mutate the order.

The base coin line reads the wallet's spendable balance when the form opens;
exchange hedge balances and other limits are still checked independently by
preview. Tooltips explain each editable field and switch. Add CEX includes an
explicit supported-exchange name selector (MEXC/Gate), rather than accepting a
name for an unimplemented adapter.

The sidebar polls `get_directly_connected_peers` on local KDF every 15 seconds,
counts peer IDs once regardless of address count, and clears unavailable/stale
results. Polls do not overlap and stop on widget disposal. Remote traffic
continues to use Tor.

## Responsive dashboard and balance refresh (2026-10-03)

Maker rows contain only the order data columns. UUID, copy, Details, Pause/Start
and Modify share a wrapping footer that stays inside the viewport. At narrow
widths, order data uses labelled cells rather than clipped columns. Text can be
selected throughout the page; Copy UUID copies the exact published identifier.
Existing confirmation, pause and modification eligibility rules are preserved.

MY CEXs can be collapsed. When expanded, the selected, configured exchange is
read automatically after connection and every 60 seconds after the previous
attempt completes. A countdown and last-successful-update time show freshness.
The last successful balances remain visible during refresh and after a failed
request, with an explicit failure label. A valid empty result replaces old
balances. Each exchange has a separate display cache. Polls never overlap, wait
while engine operations are busy, and stop when collapsed or the page is disposed.
Late replies from replaced engine sessions or API credentials are ignored.

These snapshots are read-only display data. They do not extend MM_Engine's
short-lived sizing or hedge coverage leases. Preview and live publication still
perform the engine's own freshness and risk checks. No engine release or API
change is required for this dashboard update.

## Live permission and selected orders (2026-10-03)

The visible engine name is **P2Pirate Trading Engine**. GitHub URLs, repository
identity checks, environment variables, installation directories and the
`MM_ENGINE_READY`/`MM_ENGINE_STOPPED` framing retain their existing technical
names for compatibility. The window title is `P2Pirate | Desktop`.

Start live trading pauses persisted enabled strategies through the existing
pause-all endpoint **before** stopping and restarting with live permissions.
It does not invoke start-all. Failure to pause/withdraw blocks this transition.
Stop live trading also pauses configurations and returns to preview, retaining
the existing refusal to stop while owned swaps or unresolved problems remain.

Each eligible paused, disabled, unpublished order has a checkbox. The header
selects/deselects all eligible orders; partially selected rows use a mixed-state
checkbox. Selection itself and entering live mode do not activate orders.
Start selected orders requires live mode and one confirmation listing the order
numbers and markets. It sends an individually confirmed start request only for
each selected ID. Deleted, exhausted, running and review-required rows are not
eligible. An error stops further requests, refreshes the visible state and
reports confirmed starts without claiming an ambiguous request did not execute.
Selection of already activated rows is cleared after status refresh.

The persistent wallet live preference and crash-recovery behavior remain in
place: orders explicitly started by the user may resume when reopening the
wallet. The revised enable-live notice explains both the separate activation
step and this behavior. No engine API or repository migration is required.

## External CEX plugin catalog (2026-10-04)

CEX-specific public configuration **and executable adapters** now belong to
`p2piratedotcom/CEX_configs`, independently of the wallet and common engine.
The first use of a compatible installed engine prompts to download the supported
plugins. The trading-engine page adds a **CEX plugins** check/download action.
MEXC/Gate credentials keep their current Secret Service profile and namespace;
no re-entry is required. API keys are never included in public configuration.

Downloads pin one catalog commit, verify repository identity/protocol/paths/file
sizes/SHA-256, install an immutable snapshot and switch the current pointer only
after complete validation. The engine verifies it again. A failed update retains
the previous snapshot. Existing snapshots work offline; corrupt files fail closed.
CEX choices in the dashboard, API-key dialog and order form come from the verified
catalog/engine capabilities, allowing new Spot v1 venues without GUI edits.

Before updating, orders are paused/withdrawn and the engine is stopped. Existing
shutdown restrictions for active swaps remain in force. The wallet clears live
permission and reconnects in preview. No update automatically starts orders.
The normal Tor requirement applies to repository downloads and adapter traffic.

The wallet probes `plugin-capabilities` before supplying KDF secrets or live flags.
Normal engine release installation requires compatibility metadata
`plugin_protocol: 1`. The old immutable release lacks it; the paired new engine,
GUI and initial catalog must be published together before normal installation
can use this feature. For local candidates only, `P2PIRATE_CEX_PLUGIN_DIR` selects
an absolute verified checkout (and takes precedence over downloaded snapshots).
Use the existing checksum-verified local engine override for the new binary.

Plugin code runs in child processes inside the engine executable; it does not
require system Python. This is failure containment, **not an OS security sandbox**.
Publishing the catalog is trusted code distribution; SHA-256 checks are not an
independent signature. Plugin review belongs in its repository.

The common contract covers Spot limit orders, key+secret authentication and USDT
hedge routes. Kraken/Binance are next plugin projects and are not yet offered in
the catalog. Their native signing, nonce, asset aliases and client-ID mapping
belong to the adapters. Protocol requirements and official references are in
`CEX_configs/PROTOCOL.md`. Changes outside this contract require an explicit
versioned engine extension.

Local checks: 237 GUI unit/widget tests passed, 2 existing skips; scoped static
analysis is clean. Separate engine and plugin fixture tests make no funded orders.
