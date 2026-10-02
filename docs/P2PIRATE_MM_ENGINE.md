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
engine. The current local CEX worker requires MEXC credentials even for a Gate
strategy. The operator explicitly confirms live mode, then previews and saves
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
