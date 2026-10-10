# Selective CEX plugin downloads

The wallet loads repository identity, the current public commit and its bounded
catalog before showing a checkbox list. No adapter/configuration is downloaded
until the user chooses at least one exchange and confirms Download selected.
The dialog starts with no selection and displays available/installed versions.
Cancellation, an empty selection and an already-current selection leave the
engine and installed snapshot untouched. Wallet identity is fenced across the
catalog request, selection and existing migration flow. Venue and merged-count
preflight rejects invalid selections before any recovery/pause/stop changes.

Selected exchanges are downloaded at the approved catalog commit. Unselected
installed exchanges remain available with their existing verified bytes; this
flow does not uninstall plugins or modify API keys. The combined catalog keeps
protocol 1 and the original strict entry schema, and is supported by the engine's
existing partial-catalog verifier. Each file retains path, size, SHA-256,
configuration, source-bundle and symlink checks. Each retained plugin keeps its
original license digest. When the shared
repository LICENSE changes, the old verified license bytes are carried in
`licenses/<SHA256>.txt`. An exchange absent from the latest catalog stays
available with its original code, source and license while selected exchanges
can still update; no removal or strategy rewrite is implicit.

A selective snapshot directory is named `<catalog-commit>-<snapshot-SHA256>`;
`current` names that immutable directory. Legacy 40-character commit pointers
remain readable. The suffix binds both the catalog bytes and the provenance
sidecar through
fixed-length SHA-256 hashes with domain separation. A selective snapshot must
include its bounded `plugin-sources.json` sidecar, which records the actual
source commit and license digest for each retained or downloaded venue. The
snapshot's commit identifies the catalog used for the
latest selection, not a claim every retained adapter was updated. The engine
receives the directory and does not need a protocol/schema change. Older wallet
versions do not understand the new pointer form; old snapshots are preserved,
not overwritten or deleted by this change.

Legacy full-download offline reuse is restricted to non-selective commit
snapshots; a partial snapshot cannot satisfy a legacy full request.

Concurrent installations are rejected instead of returning another request's
result. Staging is verified before activation; failures retain the prior pointer.
The existing migration reconciles recovery, pauses makers, checks safe engine
shutdown and reconnects in preview. Choosing downloads never authorizes trades
or waives unresolved swap/hedge obligations.

Implementation validation is separate from release and deployment. No new
unit/widget tests or funded operations were run for this change. Static Dart
analysis and formatting results are recorded in the task; an interactive dialog
check and binary packaging are not implied by source availability.
