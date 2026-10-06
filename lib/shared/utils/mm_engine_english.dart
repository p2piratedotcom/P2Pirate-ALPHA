/// English presentation of legacy engine diagnostics. Apply only at the widget
/// boundary: original response values, logs, identifiers, comparisons and
/// confirmation payloads must remain unchanged. No numbers are reformatted.
String mmEngineEnglish(Object? value) {
  var text = value?.toString() ?? '';
  for (final entry in _patterns) {
    text = text.replaceAllMapped(entry.$1, (match) {
      final original = match[2]!;
      final translated = original == original.toUpperCase()
          ? entry.$2.toUpperCase()
          : entry.$2;
      return '${match[1]}$translated';
    });
  }
  return text;
}

final _patterns = (() {
  final phrases = _phrases.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));
  return [
    for (final entry in phrases)
      (
        RegExp(
          '(^|[^A-Za-zÀ-ÿ_])(${RegExp.escape(entry.key)})(?=\$|[^A-Za-zÀ-ÿ_])',
          caseSensitive: false,
        ),
        entry.value,
      ),
  ];
})();

const _phrases = <String, String>{
  'valore positivo richiesto': 'positive value required',
  'valore non negativo richiesto': 'non-negative value required',
  'asset CEX deve essere maiuscolo': 'CEX asset must be uppercase',
  "specificare l'asset Spot CEX per": 'specify the CEX Spot asset for',
  'coin distinte richieste': 'distinct coins required',
  'replenish deve essere booleano': 'replenish must be a boolean',
  'premium deve essere compreso tra -100% e +100%':
      'premium must be between -100% and +100%',
  'deve essere minore di 1': 'must be less than 1',
  'Selezionare da una a 24 coin CEX': 'Select between one and 24 CEX coins',
  'Selezionare almeno una coin con percentuale maggiore di zero':
      'Select at least one coin with a percentage greater than zero',
  'Selezione maker cambiata: avviare una nuova analisi':
      'Maker selection changed: start a new analysis',
  'Selezionare esplicitamente gli ordini maker':
      'Explicitly select maker orders',
  'Percentuali del budget CEX mancanti': 'CEX budget percentages missing',
  'Confermare l’operazione mostrata prima dell’esecuzione':
      'Confirm the displayed operation before execution',
  'Percentuali CEX non valide: usare 0–100% a passi di 5%':
      'Invalid CEX percentages: use 0–100% in 5% increments',
  'Budget non valido: aggiornare la selezione':
      'Invalid budget: refresh the selection',
  'Budget CEX scaduto o selezione cambiata: selezionare di nuovo e analizzare':
      'CEX budget expired or selection changed: select again and Analyze',
  'Esito rebalance incoerente: budget bloccato':
      'Inconsistent rebalance outcome: budget held',
  'Nessun target maker residuo da coprire':
      'No remaining maker target to cover',
  'Lato hedge non consentito dalle regole attuali':
      'Hedge side not permitted by current rules',
  'Maker non copribile con il riferimento corrente':
      'Maker cannot be hedged at the current reference',
  'Nessun target hedge disponibile': 'No hedge target available',
  'non utilizzabile, coppia Spot USDT o regole/commissioni non disponibili':
      'cannot be used; Spot USDT pair or rules/fees unavailable',
  'Contesto rebalance non valido': 'Invalid rebalance context',
  'Contesto rebalance locale non configurato':
      'Local rebalance context not configured',
  'Riferimento ideale non valido': 'Invalid ideal reference',
  'Rebalance CEX pendente: aprire Trading Engine → MY CEXs → Refresh trade status (oppure [8] nella TUI) prima di ripartire':
      'CEX rebalance pending: open Trading Engine → CEX REBALANCE → Refresh trade status (or [8] in the TUI) before resuming',
  'Prima mettere in pausa tutti i mercati KDF e attendere gli swap':
      'First pause all KDF markets and wait for swaps',
  'Metterle in pausa o risolverne gli avvisi prima di operare':
      'Pause them or resolve their warnings before proceeding',
  'Riconciliazione KDF non aggiornata: attendere una lettura recente':
      'KDF reconciliation is not current: wait for a recent read',
  'Riconciliazione KDF incompleta: risolvere swap/ordini prima del rebalance':
      'KDF reconciliation incomplete: resolve swaps/orders before rebalancing',
  'Mettere in pausa anche il repricing KDF': 'Also pause KDF repricing',
  'Usare la pausa MANUALE del repricing, non la pausa automatica':
      'Use MANUAL repricing pause, rather than automatic pause',
  'Journal hedge non pronto o operazioni ancora pendenti':
      'Hedge journal not ready or operations still pending',
  'Commissioni CEX non disponibili': 'CEX fees unavailable',
  'Timestamp di mercato non valido durante l’analisi':
      'Invalid market timestamp during analysis',
  'book incompleto durante l’analisi': 'incomplete book during analysis',
  'Permessi sulle coppie CEX non verificabili: nessun piano valido':
      'CEX pair permissions cannot be verified: no valid plan',
  'Coppia hedge non autorizzata per la API selezionata':
      'Hedge pair not authorized for the selected API',
  'Rebalance eseguibile solo con il servizio KDF locale':
      'Rebalance execution requires the local KDF service',
  'Esito da verificare: usare Aggiorna stato. NON reinviare la proposta':
      'Outcome needs verification: use Refresh trade status. DO NOT resubmit the proposal',
  'non autorizzata per questa API': 'not authorized for this API',
  'ancora aperti': 'still open',
  'prima degli arrotondamenti': 'before rounding',
  'lettura account Spot': 'Spot account read',
  'verifica formato saldi': 'balance format validation',
  'credenziali non disponibili': 'credentials unavailable',
  'credenziali cambiate durante la lettura; aggiornare i saldi':
      'credentials changed during reading; refresh balances',
  'caricamento credenziali': 'loading credentials',
  'simboli Spot autorizzati non validi': 'invalid authorized Spot symbols',
  'fallita': 'failed',
  'rinnovo consegnato ma ripubblicazione ancora sospesa':
      'renewal delivered but republication remains suspended',
  'autorizzazioni non verificate': 'permissions unverified',
  'credenziali o conferma non valide': 'invalid credentials or confirmation',
  'Invio wallet non configurato: aggiornare e riavviare il servizio locale':
      'Wallet send not configured: update and restart the local service',
  'ATTENZIONE: circuit breaker non ha cancellato gli ordini':
      'WARNING: circuit breaker did not cancel orders',
  'ATTENZIONE: ordini posseduti non cancellati':
      'WARNING: owned orders were not cancelled',
  'numero di gambe hedge non valido': 'invalid hedge leg count',
  'route hedge duplicata o non valida': 'duplicate or invalid hedge route',
  'gamba parzialmente eseguita: nessun reinvio automatico':
      'leg partially filled: no automatic resubmission',
  "book vuoto prima dell'invio": 'empty book before submission',
  'pubblicazione precedente non risolta: nessun reinvio':
      'previous publication unresolved: no resubmission',
  'lato hedge originale non valido': 'invalid original hedge side',
  'esecuzioni MEXC non verificabili ora; inversione bloccata':
      'MEXC fills cannot currently be verified; reversal blocked',
  'esecuzioni MEXC non complete o discordanti':
      'MEXC fills incomplete or inconsistent',
  'controvalore netto originale non valido': 'invalid original net notional',
  'Lato rebalance non valido': 'Invalid rebalance side',
  'rimborso KDF maker non verificato; inversione bloccata':
      'KDF maker refund unverified; reversal blocked',
  'esito hedge originale mancante': 'original hedge outcome missing',
  'inversione in perdita dopo le commissioni (limite netto':
      'reversal would lose value after fees (net limit',
  'ticker/asset non valido': 'invalid ticker/asset',
  'la route deve essere Spot asset/USDT; USDT non usa un book':
      'route must be Spot asset/USDT; USDT does not use a book',
  'route Spot non negoziabile': 'Spot route cannot be traded',
  'verificare/aggiornare il worker': 'check/update the worker',
  'non conferma tutte le route richieste':
      'does not confirm all required routes',
  'identificativo richiesta Scala non valido':
      'invalid Scale request identifier',
  'mercato speculare non valido': 'invalid mirrored market',
  'riduzione KDF non confermata; livelli nuovi restano in pausa':
      'KDF reduction unconfirmed; new levels remain paused',
  'Scala registrata con esito parziale: controllare i livelli':
      'Scale recorded with partial outcome: check levels',
  'riconciliazione automatica KDF non conclusa':
      'automatic KDF reconciliation incomplete',
  'risolvere le anomalie prima di eliminare':
      'resolve anomalies before deleting',
  'premere H per mettere in pausa prima di eliminare':
      'press H to pause before deleting',
  'swap non riuscito o rimborsato': 'swap failed or refunded',
  'Swap non riuscito: verificare rimborso ed eventuale hedge prima di riprendere':
      'Swap failed: verify the refund and any hedge before resuming',
  'stato swap attivi KDF incompleto': 'incomplete KDF active-swap state',
  'Pubblicazione verificata dopo risposta incerta':
      'Publication verified after an uncertain response',
  'Nessun reinvio; verifica in sola lettura ogni 10 s':
      'No resubmission; read-only verification every 10 s',
  'pubblicazione precedente ancora in verifica':
      'previous publication still being verified',
  'riconciliazione generale non pronta': 'general reconciliation not ready',
  'storico KDF non conferma cancellazione senza swap':
      'KDF history does not confirm cancellation without a swap',
  'Ultimo UUID cancellato senza swap; nessun aggiornamento ritentato':
      'Last UUID cancelled without a swap; no update retried',
  'Swap concluso, hedge verificato e nessun UUID aperto':
      'Swap finished, hedge verified and no open UUID',
  'mettere in pausa e risolvere le anomalie prima di modificare':
      'pause and resolve anomalies before modifying',
  'importo effettivo dello swap non valido': 'invalid actual swap amount',
  'richiesto margine di rientro del 25%': '25% re-entry margin required',
  'ripubblicazione': 'republication',
  'impegno': 'reserved amount',
  'profondità': 'depth',
  'non configurato': 'not configured',
  'non disponibili': 'unavailable',
  'non negativo': 'non-negative',
  'non valido': 'invalid',
  'live non pronto': 'live not ready',
  'nessun limite': 'no limit',
  'richiesto': 'required',
  'Lettura': 'Read',
  'prezzo/quantità entro soglia': 'price/quantity within threshold',
  'attesa snapshot distinti/intervallo minimo':
      'waiting for distinct snapshots/minimum interval',
  'Strategia messa in pausa': 'Strategy manually paused',
  'Arresto del servizio': 'Service shutdown',
  'coin non attive': 'coins are not active',
  'ritiro di sicurezza': 'safety withdrawal',
  'ripresa dopo': 'resume after',
  'e nuovi controlli MEXC': 'and fresh MEXC checks',
  'copertura ordine': 'order coverage',
  'copertura CEX insufficiente': 'insufficient CEX coverage',
  'copertura CEX assente o scaduta': 'CEX coverage missing or expired',
  'copertura automatica CEX reale non attiva':
      'live automatic CEX coverage is not enabled',
  'copertura hedge non disponibile': 'hedge coverage unavailable',
  'copertura MEXC non calcolabile': 'MEXC coverage cannot be calculated',
  'profondità hedge ridotta': 'reduced hedge depth',
  'Ritirare/ridimensionare questo ordine': 'Withdraw/resize this order',
  'ripubblicazione sospesa: attesa rinnovo completo':
      'republication suspended: waiting for complete renewal',
  'riuscito; attesa due nuovi book distinti per mercato':
      'succeeded; waiting for two new distinct books per market',
  'quantità automatica': 'automatic quantity',
  'troppo vicina al minimo': 'too close to the minimum',
  'attesa margine di stabilità del 25% prima di ripubblicare':
      'waiting for a 25% stability margin before republication',
  'quantità inferiore al minimo swap copribile su':
      'quantity below the minimum hedgeable swap on',
  'attivare entrambe le coin KDF prima di configurare la strategia':
      'activate both KDF coins before configuring the strategy',
  'un mercato/lato non può usare due CEX diversi contemporaneamente':
      'a market/side cannot use two different CEXs simultaneously',
  'mercato gestito dalla pagina Strategie: usare i suoi comandi':
      'market managed by the Strategies page: use its controls',
  "aggiornato richiesto per dimensionare l'ordine":
      'must be current to size the order',
  'riduzione automatica non disponibile con ordini legacy attivi':
      'automatic reduction unavailable with active legacy orders',
  'route della strategia opposta non disponibile':
      'opposite strategy route unavailable',
  'saldo preview scaduto durante il calcolo; riprovare':
      'preview balance expired during calculation; retry',
  'Scala richiede una strategia attiva senza anomalie':
      'Scale requires an active strategy with no anomalies',
  'Quantità Scala: inserire un importo positivo oppure 0 per la stessa quantità pubblicata':
      'Scale quantity: enter a positive amount or 0 for the same published quantity',
  "Stessa quantità non disponibile: l'ordine originale non è pubblicato. Attendere la ripresa oppure inserire una quantità esplicita":
      'Same quantity unavailable: the original order is not published. Wait for resumption or enter an explicit quantity',
  'premium già presente per questa direzione':
      'premium already exists for this direction',
  'il prezzo finale coincide con un livello esistente':
      'the final price matches an existing level',
  'Quantità aggiuntive. Riduzioni auto confermate diventano nuovi massimi per ordine. Pubblicazione sequenziale, non atomica':
      'Additional quantities. Confirmed automatic reductions become new per-order maximums. Publication is sequential, not atomic',
  'richiesta Scala già registrata: controllare i livelli senza reinviare':
      'Scale request already recorded: check levels without resubmitting',
  "Quantità dell'originale cambiata o non confermata: ripetere anteprima e conferma, senza pubblicare automaticamente":
      'Original quantity changed or unconfirmed: repeat preview and confirmation without automatic publication',
  'quantità automatica cambiata: ripetere anteprima e conferma':
      'automatic quantity changed: repeat preview and confirmation',
  'massimo due strategie per conferma':
      'at most two strategies per confirmation',
  'mercato già gestito: fermare/rimuovere prima il vecchio target':
      'market already managed: stop/remove the previous target first',
  "Quantità equivalente in asset base all'anteprima corrente; i limiti di sicurezza possono ridurla se automatica":
      'Equivalent base-asset quantity at the current preview; safety limits may reduce it in automatic mode',
  'gruppo non modificabile o premium già presente':
      'group cannot be modified or premium already exists',
  "mettere in pausa e ritirare l'ordine prima di modificare":
      'pause and withdraw the order before modifying it',
  'strategia eliminata: creare una nuova configurazione':
      'strategy deleted: create a new configuration',
  'selezionare una o due strategie distinte':
      'select one or two distinct strategies',
  'ordine KDF ancora attivo: completare la pausa prima di eliminare':
      'KDF order still active: finish pausing before deletion',
  'UUID non più attribuito alla strategia':
      'UUID no longer owned by the strategy',
  'Swap, hedge e ordine riconciliati nello storico KDF':
      'Swap, hedge and order reconciled against KDF history',
  'Swap riconciliato; nuova quotazione dopo feed e copertura':
      'Swap reconciled; new quote after feed and coverage checks',
  'Swap sull’ordine precedente: attesa esito KDF, hedge e storico ordine':
      'Swap on the previous order: waiting for KDF outcome, hedge and order history',
  'Ordine precedente cancellato; nuova quotazione dopo i controlli correnti':
      'Previous order cancelled; new quote after current checks',
  'Ordine non visibile: attesa conferma della cancellazione o dello swap':
      'Order not visible: waiting for cancellation or swap confirmation',
  'termini dell’ordine residuo KDF non validi':
      'invalid remaining KDF order terms',
  'ordine residuo KDF in stato locale non riattivabile':
      'remaining KDF order is in a local state that cannot be resumed',
  'Ordine residuo verificato dopo swap; nuovo prezzo al prossimo controllo':
      'Remaining order verified after swap; new price at the next check',
  'Swap o match sullo stesso UUID: attesa riconciliazione prima del repricing':
      'Swap or match on the same UUID: waiting for reconciliation before repricing',
  'Cancellazione registrata; attesa scomparsa dell’UUID da KDF':
      'Cancellation recorded; waiting for the UUID to disappear from KDF',
  'ordine KDF in stato locale': 'KDF order in local state',
  'prezzo o volumi KDF non validi': 'invalid KDF price or volumes',
  'Nuovi termini verificati; attesa riconciliazione':
      'New terms verified; waiting for reconciliation',
  'ordine KDF con termini diversi sia dai precedenti sia da quelli richiesti':
      'KDF order terms match neither the previous nor the requested terms',
  'Ordine invariato; attesa riconciliazione':
      'Order unchanged; waiting for reconciliation',
  'Ordine ancora ai vecchi termini; attesa prima di riprovare la cancellazione':
      'Order still has the old terms; waiting before retrying cancellation',
  'Aggiornamento KDF incerto: annullamento di sicurezza':
      'Uncertain KDF update: safety cancellation',
  'Vecchio ordine annullato; nuova quotazione dopo i controlli correnti':
      'Old order cancelled; new quote after current checks',
  'UUID recuperato; attesa riconciliazione e controlli correnti':
      'UUID recovered; waiting for reconciliation and current checks',
  'nessun UUID attribuito alla strategia': 'no UUID owned by the strategy',
  'ultimo ordine non confermato come cancellato':
      'last order not confirmed as cancelled',
  'swap associato all’ultimo ordine; nessuna ripubblicazione':
      'swap linked to the last order; no republication',
  'almeno un ordine della strategia è ancora aperto o non attribuito':
      'at least one strategy order remains open or unowned',
  'un UUID della strategia è ancora pubblicato su KDF':
      'a strategy UUID is still published on KDF',
  'Timeout storico riconciliato; attesa feed e copertura prima della nuova pubblicazione':
      'Historical timeout reconciled; waiting for feed and coverage before republication',
  'verifica automatica in attesa': 'automatic verification pending',
  'Rimborso maker e hedge verificati; inventario MEXC conservato e copertura ricalcolata':
      'Maker refund and hedge verified; MEXC inventory retained and coverage recalculated',
  'Rimborso e hedge riconciliati; inventario MEXC conservato, attesa nuova copertura prima della pubblicazione':
      'Refund and hedge reconciled; MEXC inventory retained, waiting for new coverage before publication',
  'Swap e hedge riconciliati; attesa feed e copertura prima della nuova pubblicazione':
      'Swap and hedge reconciled; waiting for feed and coverage before republication',
  'rimuovere il target repricing precedente prima di avviare la strategia':
      'remove the previous repricing target before starting the strategy',
  'ordine di un altro gestore presente':
      'another manager owns an existing order',
  'prezzo finale già presente su un altro livello':
      'final price already exists at another level',
  'ordine assente, ma swap/stato finale da riconciliare':
      'order absent, but swap/final state needs reconciliation',
  'Riavvio durante scrittura KDF: riconciliare gli ordini prima di proseguire':
      'Restart during a KDF write: reconcile orders before continuing',
  'Ribilanciamento già in corso: attendere e aggiornare lo stato':
      'Rebalance already in progress: wait and refresh status',
  'Selezione maker non più valida': 'Maker selection is no longer valid',
  'Più ordini OPEN per lo stesso maker: verificare la riconciliazione prima del rebalance':
      'Multiple OPEN orders for one maker: verify reconciliation before rebalancing',
  'Selezionare esplicitamente uno o più maker':
      'Explicitly select one or more makers',
  'Attivare la modalità live per eseguire operazioni Spot; i maker devono restare in pausa':
      'Enable live mode to execute Spot trades; makers must remain paused',
  'Nessun ordine maker configurato per questo CEX':
      'No maker order configured for this CEX',
  'Identità budget CEX non valida': 'Invalid CEX budget identity',
  'Riferimento maker cambiato: ricalcolare la copertura ideale':
      'Maker reference changed: recalculate ideal coverage',
  'Quantità pubblicate aumentate: ricalcolare la copertura ideale':
      'Published quantities increased: recalculate ideal coverage',
  'Proposta assente, già utilizzata o servizio riavviato: ricalcolare':
      'Proposal missing, already used or service restarted: Analyze again',
  'Esito CEX non verificabile ora. Non reinviare: riprovare Aggiorna stato':
      'CEX outcome cannot currently be verified. Do not resubmit: retry Refresh trade status',
  'Dati di mercato scaduti durante l’analisi':
      'Market data expired during analysis',
  'Prezzo, saldo o quantità cambiati: ricalcolare e confermare di nuovo':
      'Price, balance or quantity changed: Analyze and confirm again',
  'Rebalance CEX o pubblicazione KDF in corso: riprovare dopo il completamento':
      'CEX rebalance or KDF publication in progress: retry after completion',
  'Attesa rebalance terminata: un ciclo CEX o una pubblicazione KDF non si è ancora concluso. Questa richiesta non ha inviato ordini. Attendere, poi eseguire una nuova analisi':
      'Rebalance wait expired: a CEX cycle or KDF publication is still in progress. This request submitted no orders. Wait, then Analyze again',
  'La copertura aggiornata non è verificabile: risolvere il blocco e ricalcolare':
      'Updated coverage cannot be verified: resolve the blocker and Analyze again',
  'Identità del trade approvato non valida: nuova analisi richiesta':
      'Invalid approved trade identity: a new analysis is required',
  'Le regole CEX non consentono più il trade approvato':
      'CEX rules no longer permit the approved trade',
  'Quantità o prezzo approvati non rispettano i minimi/passi CEX attuali':
      'Approved quantity or price does not meet current CEX minimums/increments',
  'Il limite BUY approvato non è più eseguibile entro l’impatto consentito: analizzare e confermare il nuovo prezzo':
      'The approved BUY limit is no longer executable within the allowed price impact: Analyze and confirm a new price',
  'Il limite SELL approvato non è più eseguibile entro l’impatto consentito: analizzare e confermare il nuovo prezzo':
      'The approved SELL limit is no longer executable within the allowed price impact: Analyze and confirm a new price',
  'Profondità attuale insufficiente per la quantità approvata: nessun ordine inviato':
      'Current depth is insufficient for the approved quantity: no order submitted',
  'Il deficit dell’asset è già coperto o la quantità approvata è eccessiva: ricalcolare':
      'The asset deficit is already covered or the approved quantity is excessive: Analyze again',
  'Copertura ideale già finanziata: vendita non più necessaria':
      'Ideal coverage already funded: a sale is no longer needed',
  'Il fabbisogno da finanziare si è ridotto: la vendita approvata eccede quanto serve, ricalcolare':
      'Funding needs decreased: the approved sale exceeds the required amount; Analyze again',
  'Sono presenti quotazioni legacy: rimuoverle o convertirle in strategie prima del rebalance':
      'Legacy quotes exist: remove them or convert them to strategies before rebalancing',
  'Configurazione o budget maker cambiato: ricalcolare la copertura ideale':
      'Maker configuration or budget changed: recalculate ideal coverage',
  'Commissione configurata cambiata: ricalcolare la copertura ideale':
      'Configured fee changed: recalculate ideal coverage',
  'Obblighi degli ordini aperti aumentati: ricalcolare la copertura ideale':
      'Open-order liabilities increased: recalculate ideal coverage',
  'Troppe coppie in una singola analisi: selezionare al massimo 16 mercati':
      'Too many pairs in one analysis: select at most 16 markets',
  'Copertura non eseguibile: inventario hedge protetto. Nessun piano parziale autorizzato':
      'Coverage cannot be executed: hedge inventory is protected. No partial plan authorized',
  'Strategie cambiate durante l’analisi: ricalcolare':
      'Strategies changed during analysis: Analyze again',
  'Identità rebalance CEX non verificabile: conservare il blocco e aggiornare lo stato':
      'CEX rebalance identity cannot be verified: retain the hold and refresh status',
  'Prezzo rebalance CEX discordante: conservare il blocco budget':
      'CEX rebalance price mismatch: retain the budget hold',
  'Proposta assente o scaduta: ricalcolare':
      'Proposal missing or expired: Analyze again',
  'Strategie cambiate: ricalcolare la proposta':
      'Strategies changed: Analyze the proposal again',
  'Riferimento maker, budget residuo o selezione cambiati: ricalcolare e confermare':
      'Maker reference, remaining budget or selection changed: Analyze and confirm again',
  'Saldo cambiato: la riserva di copertura non può essere utilizzata':
      'Balance changed: the coverage reserve cannot be spent',
  'Budget selezionato insufficiente: nessun ordine inviato':
      'Selected budget insufficient: no order submitted',
  'Verifiche troppo lente: ricalcolare la proposta':
      'Checks took too long: Analyze the proposal again',
  'Mercato scaduto durante le verifiche finali: ricalcolare e confermare di nuovo':
      'Market data expired during final checks: Analyze and confirm again',
  'Questa proposta è già stata inviata: aggiornare lo stato':
      'This proposal was already submitted: refresh status',
  'Ordine rebalance pendente: aggiornare lo stato, non reinviare':
      'Rebalance order pending: refresh status; do not resubmit',
  'Ricalcolare dopo esecuzione completa; nessun trasferimento effettuato':
      'Analyze again after complete execution; no transfer performed',
  'sincronizzazione orario non completata':
      'time synchronization did not complete',
  'sincronizzazione orario fallita': 'time synchronization failed',
  'Il server orario pubblico non è stato verificato entro i limiti. Riprovare; la lettura dei saldi non è ancora iniziata':
      'The public time server was not verified within the limits. Retry; balance reading has not started',
  'Configurare le chiavi e riprovare': 'Configure API keys and retry',
  'Verificare Spot Account Read e connessione Tor; riprovare':
      'Check Spot Account Read permission and the Tor connection; retry',
  'Verificare Spot Account Read e connessione; riprovare':
      'Check Spot Account Read permission and the connection; retry',
  'Controllare chiavi API, permesso Spot Account Read e connessione Tor; riprovare':
      'Check API keys, Spot Account Read permission and the Tor connection; retry',
  'lettura saldo troppo lenta: riprovare': 'Balance read took too long: retry',
  'saldo Spot non disponibile': 'Spot balance unavailable',
  'saldo Spot duplicato': 'duplicate Spot balance',
  'rinnovo copertura, fase': 'coverage renewal, stage',
  'elenco simboli non disponibile; autorizzazioni non verificate, riprova tra':
      'symbol list unavailable; permissions unverified; retry in',
  'rinnovo copertura troppo lento: saldi già scaduti; nessun permesso inviato':
      'coverage renewal too slow: balances already expired; no permission sent',
  'Importo sotto il minimo dell’hedge': 'Amount below the minimum hedge on',
  "Importo sotto il minimo dell'hedge": 'Amount below the minimum hedge on',
  'non necessariamente fondi mancanti. Aumentare la quantità (o la percentuale custom auto) e gli eventuali tetti/budget almeno al minimo indicato; poi ricontrollare la copertura residua':
      'not necessarily a funding shortfall. Increase the quantity (or custom auto percentage) and any caps/budgets to at least the stated minimum, then recheck remaining coverage',
  'Il book non consente un hedge valido: attendere più liquidità o liberare la profondità impegnata dagli altri ordini':
      'The book cannot support a valid hedge: wait for more liquidity or release depth reserved by other orders',
  'nessuna quantità coperta disponibile': 'no covered quantity available',
  'quantità fissa non coperta': 'fixed quantity is not covered',
  'i livelli della stessa coppia si sommano, le coppie diverse condividono i fondi KDF':
      'levels of the same pair are added together; different pairs share KDF funds',
  'saldo KDF vendibile residuo': 'remaining spendable KDF balance',
  'sono al netto della copertura degli altri ordini':
      'exclude coverage reserved for other orders',
  'Puoi provare al massimo': 'You can try at most',
  "Nessuna quantità pubblicabile: ridurre l'importo non basta; attendere più liquidità o liberare/rifornire la risorsa limitante":
      'No publishable quantity: reducing the amount is insufficient; wait for more liquidity or release/replenish the limiting resource',
  'Minimo copribile': 'Minimum hedgeable amount',
  'Massimo coperto': 'Maximum covered amount',
  'quantità non rappresentabile (precisione massima 8 decimali)':
      'quantity cannot be represented (maximum precision: 8 decimal places)',
  'quantità non copribile con residuo di precisione':
      'quantity cannot be hedged with the precision residual',
  'entro 0.01 USDT. Ridurre la quantità o usare la modalità automatica':
      'within 0.01 USDT. Reduce the quantity or use automatic mode',
  'Il passo di quantità': 'The quantity increment',
  'impedisce un hedge con residuo entro 0.01 USDT alla quantità disponibile; attendere più capacità o scegliere una route più precisa':
      'prevents a hedge with residual within 0.01 USDT at the available quantity; wait for more capacity or choose a more precise route',
  'Profondità residua MEXC per': 'Remaining MEXC depth for',
  'Quantità scelta con la percentuale custom auto':
      'Quantity selected using the custom auto percentage',
  'Massimo impostato': 'Configured maximum',
  'Saldo KDF residuo': 'Remaining KDF balance',
  'percentuale custom auto: maggiore di 0 e al massimo 100%':
      'custom auto percentage: greater than 0 and at most 100%',
  'identificativo strategia richiesto (max 100 caratteri)':
      'strategy identifier required (maximum 100 characters)',
  'base non-USDT e asset distinti richiesti':
      'non-USDT base and distinct assets required',
  'modalità consentite: auto, fixed': 'allowed modes: auto, fixed',
  'quantità fissa superiore al massimo per ordine':
      'fixed quantity exceeds the per-order maximum',
  'impatto massimo 1%; quota di profondità massima 50%':
      'maximum price impact 1%; maximum depth share 50%',
  'almeno 3 snapshot e intervallo positivo richiesti':
      'at least 3 snapshots and a positive interval required',
  'Limite stimato dallo snapshot, non garanzia di liquidità futura. USDT non equivale necessariamente a USD':
      'Limit estimated from the snapshot, not a guarantee of future liquidity. USDT is not necessarily equivalent to USD',
  'prezzo risultante non positivo': 'resulting price is not positive',
  'creare una strategia o una coppia di strategie':
      'create one strategy or a pair of strategies',
  'un solo ordine per mercato e lato': 'only one order per market and side',
  'identificativo archiviato: creare una nuova strategia':
      'identifier archived: create a new strategy',
  'esiste già una strategia per questa direzione/premium: usare Scala con un premium diverso':
      'a strategy already exists for this direction/premium: use Scale with a different premium',
  'una modifica non può cambiare ticker, mapping, direzione o CEX':
      'an edit cannot change ticker, mapping, direction or CEX',
  'campi stato strategia non validi': 'invalid strategy state fields',
  'riduzione riservata a quantità automatica positiva':
      'reduction is reserved for a positive automatic quantity',
  "ordine già assegnato a un'altra strategia":
      'order already assigned to another strategy',
  'mettere la strategia in pausa e risolvere le anomalie prima di eliminarla':
      'pause the strategy and resolve anomalies before deleting it',
  'swap non risolti: impossibile eliminare la strategia':
      'unresolved swaps: cannot delete the strategy',
  'prezzo di riferimento assente; creare una preview maker prima del rebalance':
      'reference price missing; create a maker preview before rebalancing',
  'Prezzo hedge non valido': 'Invalid hedge price',
  'Quantità di riferimento sotto il minimo hedge':
      'Reference quantity below the hedge minimum',
  'Quantità di riferimento sopra il massimo hedge':
      'Reference quantity above the hedge maximum',
  'Copertura finanziaria comune massima stimata':
      'Estimated maximum shared financial coverage',
  '% dei target selezionati, inclusa riserva del 20%. Non modifica quantità o stato dei maker; non autorizza maker sotto i minimi hedge':
      '% of selected targets, including a 20% reserve. Does not change maker quantities or states; does not authorize makers below hedge minimums',
  'Copertura completa non raggiungibile con questi budget, fondi protetti, minimi e profondità. Aumentare le percentuali o scegliere altri fondi/meno maker; i controlli live restano obbligatori':
      'Full coverage cannot be reached with these budgets, protected funds, minimums and depth. Increase percentages or choose other funds/fewer makers; live checks remain mandatory',
  'Le coin selezionate non hanno saldo Spot disponibile':
      'Selected coins have no available Spot balance',
  'Coin non attiva o saldo spendibile non disponibile':
      'Coin inactive or spendable balance unavailable',
  'Identità della strategia non valida o duplicata':
      'Invalid or duplicate strategy identity',
  'Configurazione di un ordine pubblicato non disponibile':
      'Published order configuration unavailable',
  'saldo KDF spendibile non disponibile; impossibile dimensionare il target automatico, aggiornare e riprovare':
      'spendable KDF balance unavailable; cannot size the automatic target; refresh and retry',
  'Analisi copertura incompleta': 'Coverage analysis incomplete',
  'Nessun trade o trasferimento suggerito; verificare le strategie indicate e aggiornare il mercato':
      'No trade or transfer suggested; check the listed strategies and refresh market data',
  'quantità effettivamente pubblicata': 'actual published quantity',
  'prossimo ordine auto, limitato dal saldo spendibile KDF e dai limiti della strategia/mercato':
      'next automatic order, limited by spendable KDF balance and strategy/market limits',
  'quantità fissa configurata': 'configured fixed quantity',
  'già inclusi commissioni e riserva del 20%':
      'fees and a 20% reserve already included',
  'Fondi insufficienti per il target: mancano circa':
      'Insufficient target funding: shortfall approximately',
  'Prima completare la copertura +20% su':
      'First complete coverage plus 20% reserve on',
  'nessuna eccedenza trasferibile finché esistono deficit':
      'no transferable surplus while deficits remain',
  'saldo KDF non disponibile; trasferimento non calcolabile':
      'KDF balance unavailable; transfer cannot be calculated',
  'Nessun ordine aperto, ma queste strategie possono ripubblicare o richiedono verifica':
      'No open orders, but these strategies may republish or require review',
  'Copertura multi-coin non conclusa: verificare tutte le gambe hedge':
      'Multi-coin coverage incomplete: verify every hedge leg',
  'Ordini maker cambiati o eliminati: ricalcolare':
      'Maker orders changed or deleted: Analyze again',
  'troppo lenta: riprovare, nessun piano valido':
      'too slow: retry; no valid plan',
  'non compatibili con la quantità fissa':
      'incompatible with the fixed quantity',
  "La riserva è calcolata sull'intera quantità configurata, senza ridurla. Riequilibrare i saldi non risolve un limite del book":
      'The reserve covers the full configured quantity without reducing it. Rebalancing balances cannot resolve a book limit',
  'oppure attendere maggiore profondità': 'or wait for more depth',
  'verificare il saldo KDF spendibile e i limiti/budget, oppure attendere maggiore profondità; anche il 100% auto non raggiunge ora il margine stabile':
      'check spendable KDF balance and limits/budgets, or wait for more depth; even 100% auto cannot currently reach the stability margin',
  'Ordine e swap conclusi verificati nello storico KDF':
      'Completed order and swaps verified against KDF history',
  'recupero: ordine assente o ambiguo; nessun reinvio':
      'recovery: order absent or ambiguous; no resubmission',
  'recupero: dati diversi, incompleti o ordine già abbinato; verifica manuale richiesta':
      'recovery: data differs, is incomplete or order already matched; manual review required',
  'recupero: UUID già terminale, non riattivabile':
      'recovery: UUID already terminal; cannot resume',
  'preflight troppo lento: ricalcolare il piano prima di pubblicare':
      'preflight too slow: recalculate the plan before publication',
  'ordine assente, cambiato o con swap in corso':
      'order absent, changed or has an active swap',
  'termini ordine KDF non validi': 'invalid KDF order terms',
  'Ribilanciamento non disponibile: aggiornare il motore':
      'Rebalance unavailable: update the engine',
  'motore strategie non disponibile': 'strategy engine unavailable',
  'identificativi strategie non validi': 'invalid strategy identifiers',
  'confermare tutte le strategie da mettere in pausa ed eliminare':
      'confirm all strategies to pause and delete',
  "confermare l'identificativo esatto della strategia da eliminare":
      'confirm the exact strategy identifier to delete',
  "confermare l'identificativo esatto della strategia":
      'confirm the exact strategy identifier',
  'azione strategia sconosciuta': 'unknown strategy action',
  'superiore al massimo': 'exceeds the maximum',
  'minimo copribile': 'minimum hedgeable amount',
  'disponibili netti': 'net available',
  'netti disponibili': 'net available',
  'necessari per comprare': 'required to buy',
  'necessari per vendere': 'required to sell',
  'con questo snapshot': 'with this snapshot',
  'I saldi': 'Balances',
  'vuoto o incrociato': 'empty or crossed',
  'con questo book, aumentare la percentuale custom auto dal':
      'with this book, increase the custom auto percentage from',
  'ad almeno circa': 'to at least approximately',
  'soglia di rientro stabile (+25%)': 'stable re-entry threshold (+25%)',
  'maggiore di quella configurata; aggiornare il margine commissioni':
      'exceeds the configured fee; update the fee margin',
  'Esito rebalance discordante: conservare il blocco e aggiornare lo stato':
      'Rebalance outcome mismatch: retain the hold and refresh status',
  'Modalità prova': 'Preview mode',
  'esecuzione': 'execution',
  'disabilitata': 'disabled',
  'commissione': 'fee',
  'quantità sotto il minimo': 'quantity below the minimum',
  'profondità insufficiente': 'insufficient depth',
  'prezzo maker aperto': 'open maker price',
  'quantità maker ideale': 'ideal maker quantity',
  'quantità hedge ideale': 'ideal hedge quantity',
  'profondità condivisa': 'shared depth',
  'quantità approvata': 'approved quantity',
  'prezzo limite approvato': 'approved limit price',
  'quantità pubblicata': 'published quantity',
  'prezzo pubblicato': 'published price',
  'quantità ordine': 'order quantity',
  'prezzo ordine': 'order price',
  'quantità eseguita': 'filled quantity',
  'prezzo eseguito': 'fill price',
  'saldo KDF': 'KDF balance',
  'saldo Spot': 'Spot balance',
  'prezzo fisso': 'fixed price',
  'quantità fissa': 'fixed quantity',
  'quantità hedge non valida': 'invalid hedge quantity',
  'fondi Spot insufficienti per tutte le gambe':
      'insufficient Spot funds for all legs',
  'copertura incompleta; residuo registrato, richiesta verifica':
      'coverage incomplete; residual recorded; review required',
  'stato ordine MEXC ancora incerto': 'MEXC order state still uncertain',
  'identità risposta MEXC non valida': 'invalid MEXC response identity',
  'quantità eseguita MEXC non valida': 'invalid MEXC filled quantity',
  'prezzo eseguito MEXC oltre il limite registrato':
      'MEXC fill price exceeds the recorded limit',
  "liquidità cambiata prima dell'invio; limite originale non allargato":
      'liquidity changed before submission; original limit was not widened',
  'profondità MEXC insufficiente entro 1%': 'insufficient MEXC depth within 1%',
  'permesso VPS non rinnovato: una copertura richiede attenzione':
      'VPS permission not renewed: a hedge requires attention',
  'Invio wallet KDF da verificare: aprire Portafoglio → Invia → Storico e aggiornare il TXID. Trading sospeso per non spendere fondi di esito incerto':
      'KDF wallet send needs verification: open Wallet → Send → History and refresh the TXID. Trading is suspended to avoid spending funds with an uncertain outcome',
  'identità o esito hedge originale non verificabile':
      'original hedge identity or outcome cannot be verified',
  'quantità hedge originale discordante': 'original hedge quantity mismatch',
  'hedge precedente di swap fallito; base e commissioni da verificare prima di qualsiasi inversione. Conservare i fondi':
      'previous hedge belongs to a failed swap; verify base amount and fees before any reversal. Preserve the funds',
  'copertura originale non conclusa; inversione bloccata':
      'original hedge incomplete; reversal blocked',
  'Conservare i fondi e ricalcolare la copertura degli ordini':
      'Preserve the funds and recalculate order coverage',
  'USDT/unità': 'USDT/unit',
  'sospesa: profondità': 'suspended: depth',
  'prezzo maker': 'maker price',
  'limite del book': 'book limit',
  'liquidità futura': 'future liquidity',
  'non verificabile': 'cannot be verified',
  'fondi insufficienti': 'insufficient funds',
  'nessun ordine inviato': 'no order submitted',
  'ordine incerto': 'uncertain order',
  'un worker MEXC/GATE usa già questo journal; aggiornare il servizio per consentire il riequilibrio coordinato':
      'a MEXC/GATE worker already uses this journal; update the service for coordinated rebalancing',
  'copertura live richiede KDF_MM_LIVE_TRADING=true':
      'live coverage requires KDF_MM_LIVE_TRADING=true',
  'Trading non disponibile o ordini': 'Trading unavailable or orders',
  'Ordine non consentito dalle regole': 'Order not permitted by the rules',
  'Modalità prova: esecuzione': 'Preview mode: execution',
  'sincronizzazione orario': 'time synchronization',
  'liquidità/minimi': 'liquidity/minimums',
  'nella copertura': 'in coverage',
  'quantità': 'quantity',
  'richiesti': 'requested',
  'necessari': 'required',
  'mancanti': 'missing',
  'mancano': 'shortfall',
  'massimo': 'maximum',
  'minimo': 'minimum',
  'saldo': 'balance',
  'prezzo': 'price',
  'eseguito': 'filled',
  'riprovare': 'retry',
  'non disponibile': 'unavailable',
};
