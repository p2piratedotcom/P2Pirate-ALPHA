# GUI task clarity and recovery

Reviewed 2026-10-06. Presentation does not authorize trades or change engine risk
policy. SDK/KDF behavior and the SDK gitlink are unchanged.

- Shared settings switches use the native Flutter switch, with a contextual name
  at every call site. Native focus, state and disposal replace the custom ticker.
  General Settings groups appearance/privacy, network, market data/assets and
  expandable advanced maintenance.
- Maker status has stable geometry and explicit stale warning. Cached rows cannot
  authorize starts. Unknown/failed balances do not become confirmed zero.
- Maker creation opens before balance I/O and reads only the selected base coin
  for display. The draft survives preview errors, Back to edit and closing/reopening the form
  to configure prerequisites. Only raw input is kept in wallet/process memory;
  logout/session changes clear it and successful saves discard it. Wallet identity
  is checked across awaits. Engine preview/save validation and paused saves remain.
- Details leads with pair, state, unit-bearing amount/price, budgets, venue and
  reason. Exact saved parameters and UUID are expandable Technical details.
- Rebalance uses checkboxes for inclusion and 5% slider/dropdown spending limits.
  Choose makers, Set spending limits and Review funding plan are distinct stages.
  Results lead with current/attainable coverage. Ideal/reference/account details
  remain expandable. Pending trade history remains visible. Backend budget,
  identity, idle, freshness, uncertainty and confirmation guards are preserved.
- Readable numbers retain tiny nonzero amounts and expose exact values in details
  or tooltip. Display precision never changes confirmed trade quantities/prices.
- Swap economics precede the book; Review swap names preparation. Missing fees
  say Calculated on review. Desktop scrolling retains focus. Bridge labels refer
  to source/target networks.
- Failed wallet-coin reads are removed from the cache; charts offer Retry. Old
  account completions cannot evict a new read. Price API test results require the
  same input URL/generation as the request.

Fixtures use disposable state; no funded swap/maker/rebalance is submitted by the
suite. Native screen-reader acceptance, release frame timing and funded flows need
separate evidence. Large-list virtualization remains a profiling candidate.

Configuration saves use `saveMmEnginePausedMaker`: modification-status refresh
is awaited before the final captured-session check and paused-save request. A
replacement engine cannot inherit an approval from a predecessor. Session adoption
clears drafts; stale dialogs cannot repopulate them through a later capture.
