# GUI navigation and display refresh

This change implements the five GUI improvements accepted after the 6 October
2026 navigation audit. It changes the Flutter client only. The external KDF and
Trading Engine binaries, endpoints, trading policies and Linux renderer setting
are unchanged.

## 1. Retain presentation state within a wallet session

- Wallet search, tab and scroll position survive navigation.
- Swap and Bridge tabs survive ordinary section changes.
- Trading Engine retains its public order/reconciliation display, balance
  snapshots, selected exchange, collapsed sections and scroll position.
- Entering the page of an already verified, running engine for the same profile
  shows that display immediately and requests confirmation in the background.
  It does not repeat installation scans or restart the service merely to view it.
- Installation and plugin checks still run on actual startup. A cold page shows
  progress while its first confirmed orders and CEX configuration are unknown.

Display memory is bounded to one wallet and engine process revision. Logout,
account replacement or a different engine process invalidates it. Snapshot
timestamps are preserved: restoring a display never makes old data fresh. No
rebalance proposal, approval, API credential or trading authorization is cached.
Reconnects and successful live/preview mode switches use the same display-session
adoption path: old snapshots and balance rows are cleared before reading the new
process, and the dashboard refresh generation rejects predecessor replies. Fresh
snapshots can then be remembered under the new revision. A failed
or wrong-wallet restart cannot relabel the old snapshot as belonging to it.
Off-page display timers are suspended, with same-session in-flight balance reads
allowed to finish. Each venue continues to have one shared display request.

## 2. Load portfolio graphs on demand

The Wallet Assets tab no longer starts Growth and Profit/Loss chart requests.
Selecting either chart loads its data; a remembered chart tab also loads on entry.
Plot visibility owners suppress periodic chart reads when no corresponding plot
is mounted. Session generations reject replies belonging to an earlier wallet.
Asset Overview summaries and the existing SDK balance subscriptions remain.
Coin Details retains its existing initial chart-support discovery.

## 3. Refresh only the affected display

- Balance countdowns use a separate local notifier rather than rebuilding both
  balance panels and the entire maker dashboard each second.
- Rebalance proposal expiry updates only its validity caption and Execute button.
- Five-second order reads still run while the page is visible. Unchanged public
  content updates the status strip without rebuilding the whole page. Original
  full models remain available for Details and command guards; timestamps and
  preview-only changes are excluded only from display equality comparison.
- Freshness transitions and errors rebuild action readiness immediately.
- Coin balance rows bind a stable stream and start from the SDK's last known
  balance rather than briefly showing an unknown value on every rebuild.
- Bridge tab subscriptions are actually cancelled when the widget is disposed.

## 4. Preserve ordinary Swap drafts

Reopening the ordinary form retains its pair, order selection and amount instead
of resetting its sell coin. Read-only limits are refreshed, and derived fee data
is invalidated. Submission still runs the original validation and confirmation
path. In-flight, confirmed and uncertain submission handling is retained.

## 5. Make readiness and unknown values explicit

- Incomplete Swap/Bridge forms disable submission and explain missing input.
- Unknown rate, fee and 24-hour change values show an em dash instead of a
  fabricated zero.
- A prominent status strip distinguishes confirmed, loading, stale and stopped
  maker data. Cached displays cannot enable maker starts before confirmation;
  existing pause/stop actions remain available.
- The swap counter explicitly says **Engine-owned swaps**.
- Long order diagnostics have a readable summary and an expandable, selectable
  full-precision version. Decimal shortening affects display text only.

## Validation and limits

Changed Dart files are formatted and statically analysed before the local commit;
the Linux release GUI and AppImage are then built. No unit, widget, integration,
funded-trade or live-wallet tests are run for this task. The live application is
not restarted as part of implementation. Runtime latency/FPS and memory gains
must be measured after the updated GUI is loaded; the earlier audit timings are
baseline observations, not measurements of this change.
