# Maker deletion and opposite-order creation

Source implementation; no funded acceptance or installed-release claim.

## Delete a maker

Each managed maker row includes Delete. A confirmation identifies the maker by
creation number and explains that its open quote is withdrawn before its
configuration is archived. Order bindings, swap/hedge history and consumption
remain durable. Cancel keeps the maker. This action affects only the selected
maker, even when an independently saved opposite maker exists.

The GUI uses `/v1/strategies/delete-group` with a single exact strategy ID and
`PAUSA ED ELIMINA <id>`. It requires a fresh status and the same wallet/process
session after confirmation and after any awaited status read. It never issues a
start/resume as recovery from failure. Unconfirmed replies leave the result
unknown: refresh the list before retrying. The maker may already be paused.
If the session changes while the deletion request is in flight, the GUI reports
that the previous session may already have paused or deleted the maker. It does
not silently report completion, clear the replacement session's selection/draft,
or resend the request against that session.

Deletion requires capability `maker_delete_pending_guard: 1`. Older engines show
a disabled Delete control with an update explanation. The companion engine
checks state again after pause, blocks unresolved publication intents (including
HELD), update intents and cancellation recovery, and retains its existing order,
reconciliation and unresolved-swap checks. A terminal owned UUID does not turn an
old publication-intent record into a new uncertain operation.

## Create both directions

The new-maker form offers an unchecked “Create the opposite maker order too”
checkbox. It requires engine capability `maker_opposite_pair: 1`; otherwise
the checkbox is disabled with an update explanation and no opposite endpoint
is called. Single-maker creation remains available. It shows the opposite
sell/buy pair and negative original premium
(e.g. +2% becomes −2%). This option is absent while modifying a saved maker and
is retained with the new-maker draft within the same wallet/process session.

The GUI asks `/v1/strategies/opposite` to derive the second specification. The
engine owns canonical routes, reciprocal orientation, exact Decimal conversions,
fixed/automatic quantity and price policies, and budgets/caps expressed in the
second maker's sold coin. The GUI does not copy numeric quantities between unlike
coins, infer unlimited funding or calculate hedge capacity itself.

Both specifications are sent together to `/v1/strategies/preview`. Confirmation
shows the two directions, premiums, sold budgets, caps, executable amounts and
prices. Saving sends one `/v1/strategies/create` request with both specifications
and `SALVA IN PAUSA`; the existing backend transaction saves both or neither.
Both are paused. Live permission and individual maker activation remain separate.

Freshness, hedge minimums, depth, reservations, daily/total budgets and uncertain
write handling remain unchanged. Saving can fail if either side cannot pass the
combined validation or already exists. A lost HTTP reply is not authorization to
blindly create a replacement pair with new IDs. No automatic financial action,
engine restart or runtime installation is part of this source change.

## Verification scope

Changed Dart files are formatted and statically analyzed. Changed engine Python
files are parsed statically. No new tests, local test runs or funded actions were
performed for this request. Runtime packaging and release are separate steps.


## Unconfirmed configuration saves

Before a new-maker save is dispatched, the GUI records its exact strategy IDs,
request time and raw form input in an in-memory marker bound to that wallet.
This is uncertainty metadata, not a preview or live approval. The form captures
its current draft before awaiting any preview/save callback.

A missing/error response gives an explicit warning that one or both paused
configurations may already exist. Every subsequent Preview/new-maker attempt
must read a confirmed maker list newer than the write request, within the current
wallet/process session. If all IDs exist, the previous save is recognized and no
second write is sent. If only some exist, creation stays blocked for inspection.
If none exist, the marker is cleared and the user may preview and confirm again
with the retained draft/IDs. There is no automatic resend.

Normal account/price/preview display memory is still discarded on session changes.
Unconfirmed IDs/raw inputs remain scoped to their original wallet within the GUI
process across navigation or engine-session replacement. They do not cross into
another wallet or grant funds authority. GUI-process restart is outside this
in-memory draft retention; backend configuration identity/history remains durable.
