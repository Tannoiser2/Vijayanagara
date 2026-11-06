# Vijayanagara — versione digitale

Versione digitale (uso personale) di **Vijayanagara: The Deccan Empires of Medieval India, 1290–1398**
di Saverio Spagnolie, Mathieu Johnson, Cory Graham e Aman Matthews (GMT Games, 2023), primo titolo della
Irregular Conflicts Series, ispirato ai giochi COIN.

Tre fazioni — **Sultanato di Delhi**, **Regno Bahmani**, **Impero di Vijayanagara** — più gli **Invasori mongoli**
mossi a turno da Bahmani e Vijayanagara. La partita finisce con l'invasione di Timur.

## Come si gioca

- **Partita locale**: per ogni fazione scegli *Tu* o *IA* (anche due o tre persone sullo stesso schermo);
  *IA contro IA* per una dimostrazione. Forza dell'IA: Rapida, Normale, Forte. Variante facoltativa «L'ombra di Timur».
- **Online**: chi crea la stanza sceglie la sua fazione e comunica il codice di 4 lettere; gli altri entrano scegliendo
  una fazione libera. L'host avvia quando vuole: i posti vuoti li gioca l'IA (calcolata dall'host).
  Se si ricarica la pagina, *Rientra nell'ultima stanza* ricostruisce la partita dal registro della stanza.
- Ogni decisione è una domanda nel pannello a destra: si risponde coi tasti o cliccando sugli spazi evidenziati.
  *Annulla* torna indietro di una decisione (solo partite locali). *Regole* apre il riassunto in italiano.
- La partita si salva da sola sul dispositivo dopo ogni atto e ogni quattro atti anche su Firebase;
  *Salva* la salva subito online. Dal menu si riprende da questo dispositivo o dal salvataggio online.

## Materiale

- Tabellone, carte e segnalini dal modulo Tabletop Simulator, **tradotti in italiano** con la grafica originale:
  36 Eventi, 8 Invasioni mongole, 3 Successioni, 2 carte Timuridi, carta Dinastia, tabellone e segnalini.
  Caratteri: El Messiri (come l'originale) e Crimson Pro al posto del Minion (entrambi OFL, in `assets/fonts`).
- Province, Prosperità e adiacenze ricavate dal tabellone (verificate con gli esempi del regolamento 1.3.5–1.3.6).

## Bot ufficiali (da fare)

Il modulo TTS non contiene il materiale Non-Player (libretto Non-Player Rules, 12 carte Ibn Battuta, 3 schede
Non-Player, carta Non-Player dei Mongoli). Per ora l'IA è a simulazioni, come in The British Way; quando il materiale
sarà nella cartella del gioco si aggiungeranno i bot ufficiali come seconda modalità.

## Struttura

- `scripts/nucleo.gd` — stato, pezzi, Controllo, Influenza, Cavalleria, mazzo e sequenza; domande/risposte
  deterministiche: la partita si ricostruisce sempre da seme + risposte (salvataggi, online, IA).
- `scripts/regole.gd` — turno sulla carta, Comandi, Decreti, battaglie, Invasioni mongole, Successioni, Timur.
- `scripts/eventi.gd` — i 36 Eventi; `motore.gd` — valutazione delle posizioni; `ia.gd` — IA a simulazioni.
- `scripts/main.gd`, `mappa.gd`, `tema.gd`, `regolamento.gd` — interfaccia (impostazione della GUI COIN di Cuba Libre);
  `rete.gd` — Firebase (radice `vijayanagara`, coperta dalla regola comune della ludoteca).
- `dati/` — mappa e carte in italiano; `assets/` — tabellone, carte, segnalini, icone, caratteri.
- Prove: `tests/sim.gd` (partite automatiche: `godot --headless -s res://tests/sim.gd -- 8 ia 40`),
  `tests/test_regole.gd`, `tests/salva.gd`, `tests/online.gd` (due client contro un finto Firebase locale),
  `tests/registro.gd` (registro completo di una partita). `tools/controlla_glifi.py` verifica i caratteri dei font.

## Pubblicazione

Il workflow `Pubblica` parte a mano (Actions → Pubblica → Run workflow) o con un commit che contiene `[pubblica]`:
esporta la versione web con Godot 4.7, la pubblica su GitHub Pages e, se ci sono i segreti `CLOUDFLARE_API_TOKEN` e
`CLOUDFLARE_ACCOUNT_ID`, sulla ludoteca privata (`https://vijayanagara.ludoteca-digitale.com/`).
