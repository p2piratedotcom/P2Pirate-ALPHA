# Linux renderer stability

## Temporary project baseline

Impeller must remain disabled on Linux until stability has been verified on the
NVIDIA Turing system used for local testing. Development and debugging:

```sh
flutter run -d linux --no-enable-impeller
flutter run -d linux --release --no-enable-impeller
```

Compiled Linux bundles and AppImages use the explicit runner setting
`fl_dart_project_set_enable_impeller(project, FALSE)` in
`linux/my_application.cc`. This setting already existed before the local build
that experienced the 2026-10-04 freezes; disabling Impeller is therefore not
a new experimental change for that build. Verify the actual executable's
renderer before drawing conclusions about Impeller as a trigger. Do not
automatically re-enable Impeller following Flutter updates. Linux integration
tests that build this runner must preserve the same setting.

## Reported test environment

User-reported baseline: Zorin OS 18.1 Pro, RTX 2070 Super (Turing), NVIDIA
595.91.07 with Open Kernel Modules / GSP, kernel 7.0.0-38-generic, X11,
Flutter 3.47.5 stable. Keep driver, kernel, session and hardware unchanged
while investigating the renderer. Driver/firmware regression and Flutter as
a trigger remain hypotheses, not established causes.

The preceding boot's kernel log on 2026-10-04 recorded NVIDIA Xid 62 and
Xid 154 (GPU Reset Required) at 19:17 Europe/Rome, followed by repeated GPU
watchdog and memory-management errors. Non-graphical work continued: the two
latest taker swaps have successful Finished events after that time.

## Evidence collection after a freeze

```sh
journalctl -k -b -1 --no-pager | rg -i 'NVRM|Xid|AER|PCIe'
```

Inspect the events immediately preceding the first Xid, including any Xid
109, 62, 45 or 154. If practical, collect `sudo nvidia-bug-report.sh` while
the GPU is still in the failed state; review the report for sensitive data
before sharing it. Record the exact executable, renderer, driver, kernel and
incident time. An Xid establishes a GPU/driver failure, not which application
triggered it. If failures recur with Impeller confirmed disabled, investigate
the driver/firmware/kernel combination in a separate controlled comparison.
