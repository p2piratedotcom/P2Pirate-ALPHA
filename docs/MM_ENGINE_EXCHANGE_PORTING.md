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
