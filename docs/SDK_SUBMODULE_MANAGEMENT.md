# P2Pirate SDK submodule

The wallet uses the Flutter SDK in `sdk/` as a Git submodule. `.gitmodules`
points to [`p2piratedotcom/komodo-defi-sdk-flutter`](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter),
which preserves the upstream SDK history and carries P2Pirate changes in
separate pull requests. This wallet commit pins SDK commit
`a5037132b86b54b44930a02cbcc2dd174acc46d4` from
[SDK PR #2](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/2),
which builds on [SDK PR #1](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/1).
These commits make P2Pirate's KDF NetID `8762` explicit, reject conflicting
startup configuration, and remove the implicit GLEEC price endpoint. The pin
is an exact commit; it does not track the tip of any SDK branch.

## Clone and check the pin

```sh
git clone --recurse-submodules https://github.com/p2piratedotcom/P2Pirate-ALPHA.git
cd P2Pirate-ALPHA
git ls-tree HEAD sdk
git -C sdk rev-parse HEAD
```

The two commands should report the same SDK SHA. In an existing clone:

```sh
git submodule sync --recursive
git submodule update --init --recursive
```

Flutter dependencies use local SDK package paths in `pubspec.yaml`, so an
initialized submodule is required before `flutter pub get --enforce-lockfile`.
Do not use `git submodule update --remote` for a reproducible checkout; that
would advance to a moving branch rather than the reviewed commit.

## Updating the SDK

1. Put each SDK behavior change in its own PR in the SDK fork.
2. Review and record the exact SDK commit SHA in the wallet PR description.
3. Update only the `sdk` gitlink in the wallet, plus any necessary integration
   changes, then review the resulting wallet diff.
4. Build against the pinned commit before publishing a release.

The source snapshot supplied on 29 September 2026 bundled a CheetahDEX KDF
2.7 executable. This gitlink pins Dart/Flutter SDK source, **not** the KDF
binary. A release needs its own documented KDF source, version, checksum and
build or acquisition process. The P2Pirate source snapshot identified the
official CheetahDEX `2.7.0-beta_968f32a` KDF from release `v0.9.4`, with
SHA-256 `bd171eeee7a1e0d43b070c8ba6ba60a845a26b3db0ef57ca25a394a2b6c02129`.
No custom Rust patch is attributed to that binary.
