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
