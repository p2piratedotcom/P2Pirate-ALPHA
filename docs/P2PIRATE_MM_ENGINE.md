# Separate MM_Engine integration

P2Pirate's Trading Engine page is a client of the separate
[`MM_Engine`](https://github.com/p2piratedotcom/MM_Engine) repository. The
engine owns strategy, pricing, risk and CEX hedge logic; P2Pirate owns the
wallet, KDF 2.7 and Tor processes. The old KDF simple market maker page is no
longer reachable from the menu. Its historical Dart types remain temporarily
because other swap/order UI still imports them; they must not publish orders
alongside MM_Engine. Existing simple maker orders and settings are not
automatically migrated to engine strategies.

## First use and updates

On Linux x86-64, enabling the Settings switch shows the Trading Engine page.
The switch alone does not download software or authorize trading. Opening the
page offers a button to check and download the newest compatible MM_Engine
release. The wallet checks the numeric GitHub repository ID, requires a
published immutable release, validates the GitHub SHA-256 digests for the
binary, `compatibility.json` and third-party license notices, checks protocol 1 and KDF 2.7 compatibility,
then verifies the downloaded bytes before installation. When Tor is enabled,
the GitHub lookup and download use the wallet's Tor HTTP bridge with no direct
fallback. Updates use the same flow and require the old engine to stop safely.

Installations live in the user's application support directory under
`mm-engine/releases/<version>/`; the current pointer is updated only after a
complete download and digest check. Each wallet profile has a separate private
state directory under `mm-engine/profiles/`. The binary and license notice
digests are checked again at every launch. No KDF password, wallet seed or CEX key is passed on the
command line or in environment variables.

## Trading flow

The wallet starts the downloaded engine as a foreground child process and
connects to its authenticated loopback API. The engine uses the existing KDF
RPC and the wallet's Tor bridge; it never starts or stops KDF or Tor. It starts
in preview mode on each login. MEXC and Gate Spot keys can be stored in the
Linux Secret Service through the wallet; key values are never returned by the
engine. The keyring profile is distinct for each wallet and from the TUI's
default profile. The current local CEX worker requires MEXC credentials even
for a Gate strategy. The operator explicitly confirms live mode, then previews and saves
each strategy paused, and confirms starting each strategy separately. Live
mode permits KDF maker orders and automatic CEX hedging; transfers remain
disabled. The chosen live mode is saved for that wallet profile; after a
restart P2Pirate automatically reconnects the engine in that mode so an
interrupted hedge can be recovered. Turning off live mode or the feature
clears that preference after a safe stop. The source engine keeps its
existing depth, exposure, repricing and reconciliation safeguards.

The wallet requests `/v1/reconciliation` before stopping the engine. Active
swaps or order problems block logout and application close. Shutdown reports
the number of uncanceled maker orders; if it cannot confirm cancellation,
P2Pirate keeps KDF and Tor available for recovery. Only one engine process
can own a profile state directory.

## Current platform scope

The wallet adapter and release recipe currently target Linux x86-64. macOS
and Windows need their own process locking, system keyring adapters and
reproducible binary release workflows before the Trading Engine page can
offer a download on those systems. The wallet itself remains desktop only.

The integration contract lives in MM_Engine's
[`docs/WALLET_INTEGRATION.md`](https://github.com/p2piratedotcom/MM_Engine/blob/main/docs/WALLET_INTEGRATION.md).
Internal engine improvements can ship in new compatible releases without a
wallet update; protocol or control changes require a wallet change.

## KDF session health during trading

An authenticated wallet is preserved when a KDF version RPC is delayed or
unavailable. Health probes retry without stopping KDF or restarting it in
unauthenticated mode. A confirmed child/native termination, valid shutdown signal or successful
wallet-names response reporting no locally recognized active wallet can still
end the session. An executable adapter that never owned a child does not
interpret an unavailable RPC as an exit. Uncertain shutdown retains process
ownership; delayed exit cleanup cannot clear a replacement child. RPC availability
is checked separately from authentication: preserving the session does not
make failed RPC requests succeed or bypass the engine's coverage safeguards.

Startup recovery runs only without an authenticated wallet, under the same
write lock as login and wallet changes. It waits for shutdown to finish and
aborts recovery if shutdown fails. A null version response is unhealthy.
These changes prevent a short RPC timeout from cancelling funded activity and
prevent a delayed shutdown from stopping a replacement process.

### Active wallet pair selection

New Maker Order has separate Base wallet coin and Quote wallet coin selectors,
both sourced from the Wallet's active CoinsBloc entries, not the engine's list
of already configured markets. The same coin cannot occupy both sides. Full KDF
IDs remain intact; unsupported or ambiguous network-to-CEX mappings require an
explicit Spot asset and must pass engine preview. The form refreshes available
balances when opened and checks Wallet activation again before preview; the
engine also validates activation. Existing saved routes remain locked on edit.
If USDT occupies the wallet base side, the submitted engine route reverses the
pair and side (and reciprocal fixed price), preserving the intended sold/bought
coins while retaining the engine's USDT quote convention.

The reconciliation update lives in the separate engine repository. Installing a
new GUI alone does not update an already-running engine process. Local candidate
builds are staged separately; do not restart a live wallet with swaps in flight
merely to load these changes.


### Initial Trading Engine loading

Installation checks are asynchronous and start with an unknown status, not
"not installed". Keep the initial availability/connect sequence behind a
circular loading indicator. Show installation prompts only after the checks
confirm a missing executable or plugin catalog. An inspection/connection error
is shown as an error, not inferred to be a missing installation. Real download
progress remains visible after initial checks. Re-entering the page must not
flash either missing-installation message for already installed components.


### Cancellation recovery visibility

The dashboard shows RECOVERING and the next readback delay when KDF did not
confirm a cancellation. Pause recovery revokes automatic strategy restart;
Modify stays unavailable until reconciliation has completed. The engine
verifies UUID identity, history, matches and swaps before resuming an automatic
strategy, and normal coverage/freshness/cooldown checks still apply. A manual
pause is never treated as permission to resume.

## Live status freshness (October 2026)

The Trading Engine page refreshes its local read-only order/strategy snapshot
every five seconds while mounted. Refresh requests do not read API credentials
or request CEX balances. A timestamp and warning identify cached or unavailable
state. Replies from an older session or preceding an action are discarded.
Starting or modifying an order requires a current confirmed display; Pause and
Stop remain available during refresh failures. Periodic reads stop when the
page is disposed, while the engine continues its normal independent lifecycle.

Pending automatic publication recovery is shown as RECOVERING. REVIEW_REQUIRED
remains appropriate for held/manual decisions. Uncertain writes are never
resent by the GUI. Persistent feed or KDF failures still require safety controls.
# CEX Spot rebalance

MY CEXs now exposes **Analyze**, **Execute rebalance**, and **Refresh trade
status**. Analysis and trade policy reside in the separate engine and use its
common Spot plugin protocol. A compatible engine advertises `rebalance: true`;
the wallet offers an update notice for older engines.

Analysis shows coverage targets, deficits and LIMIT BUY/SELL proposals for open
and enabled makers on the selected CEX, with a 20% reserve. When makers are all
paused, it analyzes their configured targets. Pause makers, wait for completed
swaps/hedges and reconciliation, then analyze again before execution. A helper
button pauses all maker configurations after confirmation, without disabling
live mode or automatically restarting them.

Each execution confirmation authorizes only the first displayed LIMIT trade.
After its verified terminal outcome, analyze again for the next step. Prices,
quantities, balances, permissions and safety conditions are checked again by the
engine. Unknown/open outcomes retain a durable hold: use **Refresh trade
status**, including after navigation or engine restart, rather than resubmitting.
No withdrawals are part of rebalance. Existing experimental adapter notices
remain applicable; live rebalance execution has not been exercised here.
