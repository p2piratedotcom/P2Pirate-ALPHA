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
