# English engine diagnostics in the wallet GUI

The wallet's labels and English translation catalog already use English. Legacy
Trading Engine messages can still contain Italian, including persisted strategy
details, coverage/depth warnings, rebalance blockers and account-read errors.

`lib/shared/utils/mm_engine_english.dart` provides their English presentation.
The phrase catalog covers the public messages emitted by the engine version used
by this wallet, with longer phrases taking precedence over shorter fragments.
It also handles dynamic messages assembled around quantities, prices and CEX
names. Numbers are not parsed or reformatted by this layer.

Examples:

| Original diagnostic | English presentation |
| --- | --- |
| prezzo/quantità entro soglia | price/quantity within threshold |
| attesa snapshot distinti/intervallo minimo | waiting for distinct snapshots/minimum interval |
| Prezzo, saldo o quantità cambiati: ricalcolare e confermare di nuovo | Price, balance or quantity changed: Analyze and confirm again |
| sincronizzazione orario fallita | time synchronization failed |

The formatter is used only when rendering explanatory text: maker notes and
Details, preview notices, rebalance goals/actions/blockers/results, balance
errors, the attention banner and engine-related errors in logout/settings/close
dialogs. Full expanded diagnostics are also English and retain their numeric
precision. Maker-note translation is reused until its input text changes.

API responses, display-memory source models, logs, database fields, status/ID
comparisons and confirmation payloads retain their original values. In
particular, Italian machine confirmation strings such as `SALVA IN PAUSA` and
`PAUSA TUTTE` are deliberately preserved in requests; these are not interface
labels. No backend or SDK package implementation is changed.

Existing English text and messages from external components with no matching
legacy phrase pass through unchanged. New engine diagnostics should be authored
in English; add any legacy wording to this catalog when introducing a new
engine version. This is a deterministic presentation catalog, not a network
translation service or a generic translator for user-entered data.

Changed-file formatting and static analysis are used before the Linux release
build. Two pre-existing informational analyzer findings in the close/menu
widgets are retained to avoid unrelated lifecycle/layout changes. No tests or
funded actions are run, and the existing live app is not restarted by this text
change.
