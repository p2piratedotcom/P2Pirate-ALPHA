# P2Pirate porting record

This fork preserves the CheetahDEX Git history and will add the P2Pirate
behaviors through reviewable, focused pull requests. The reference is the
P2Pirate Linux x86_64 source snapshot dated 2026-09-29, distributed with the
`P2Pirate-2026-09-29-linux-x86_64-with-source.zip` archive. Its SHA-256 is
`1d8602402c4be977a10ad2f80b1068ba94d1483458ce63e226d023832a2ad4ca`.
The source snapshot has no Git history. A pull request may implement the same
behavior differently to fit the current upstream code. The comparison target
is the documented behavior, not byte-for-byte equality.

## Baselines and provenance

| Component | Reference in the snapshot | Fork baseline at start of port | Handling |
| --- | --- | --- | --- |
| Flutter wallet | `0ebf84bd2d923edb28ed6a7f8e67f94da72be2f5` plus local changes | `c8d69474175bb939ffc94ab1303dc761c2c27fc5` on `cheetahdex` | Keep upstream history; port each behavior onto the current branch. |
| Dart SDK submodule | `0fef3a303eec21e04740504298adc8cddf5ce245` plus local changes | `50d0cb8c48b9803e2734ff60147f43bf874f965a` | Change SDK code in an SDK fork and pin the resulting commit from a separate wallet PR. |
| KDF binary in the reference AppImage | CheetahDEX `2.7.0-beta_968f32a`, SHA-256 `bd171eeee7a1e0d43b070c8ba6ba60a845a26b3db0ef57ca25a394a2b6c02129` | Verify before packaging | Record exact source and binary provenance. Prior ZIP-212/Reloaded work is historical and is not attributed to this binary. |
| Tor and other bundled binaries | Present in the reference AppImage | No P2Pirate release in this fork | Review the licenses and corresponding source before distributing a new build. |

The reference's main functional inventory is
`docs/PIRATE_PATCHES_AND_FIXES.md` inside the archive. Its dated sections
include older development stages. The 2026-09-29 status and the
`P2PIRATE_TRANSFER_20260929.md` summary describe the target behavior.

## Pull request sequence

Each row is a separate reviewable behavior or closely coupled set of changes.
The PR description should link this record, explain the implementation and
list the files, supported platforms and checks performed. A row is complete
only when it is present on the fork's main branch and checked against the
reference behavior.

| Order | Behavior to port | Main code area |
| --- | --- | --- |
| 1 | ARRR as the primary and only default asset; initial ZHTLC configuration flow | Wallet configuration, coin activation |
| 2 | P2Pirate name, Pirate artwork and palette, native metadata; preserve data directory compatibility | App config, themes, assets, platform runners |
| 3 | Menu and route choices, optional Trading Engine, upstream update behavior | Navigation, settings, updates |
| 4 | Analytics and automatic log export removal, with local diagnostics kept available | Analytics, feedback, logging |
| 5 | Swap desktop layout, scrolling, active-asset selection and pair reversal | Swap form and order book UI |
| 6 | Swap startup progress, timeouts and actionable errors | Taker flow and activation errors |
| 7 | Per-wallet swap history, outcome classification and recovery status | History, trading entities, recovery UI |
| 8 | ARRR address balance refresh and wallet list layout | Coin balances and wallet UI |
| 9 | USD valuation, missing-price display and configurable price API | Market prices and wallet UI; SDK where needed |
| 10 | Order book USD column, copyable maker UUID and optional exact-order matching | Order book, taker flow; SDK where needed |
| 11 | Linux Tor transport and visible status, including documented coverage limits | Linux runner, Dart networking; SDK where needed |
| 12 | UI loading, caching and profiling changes | Startup, prices, balances, UI widgets |
| 13 | Reproducible Linux build and AppImage packaging | Build scripts, dependency pins, release documentation |

These PRs can be divided further when a reviewable change is independently
useful. PRs touching the SDK must use a separate SDK branch/PR and then pin
that commit in the wallet fork. Do not replace the submodule with an untracked
source directory.

## Review and release evidence

- Keep the upstream GPL-3.0 license, copyright statements and attribution.
  Mark P2Pirate modifications and their dates in the affected release notes.
- Review the license and permitted use of artwork and trademarks separately
  from the source license. Keep third-party notices with distributed binaries.
- Check formatting and static analysis for changed Dart files. Document checks
  that cannot run and why; avoid claiming a build or swap was verified when it
  was not.
- Compare each completed behavior with the snapshot on Linux x86_64. Record
  differences that are intentional because the current upstream has evolved.
- Keep build artifacts out of source PRs. Publish a release only with the
  matching source, locked dependencies, build procedure, license notices and
  checksums. A binary checksum alone is not source provenance.
- The reference GUI and the KDF Market Maker Bot both record KDF 2.7.0-beta
  `968f32a` and NetID 8762. They have distinct processes and wallet profiles;
  this common version does not establish full swap or event compatibility.
