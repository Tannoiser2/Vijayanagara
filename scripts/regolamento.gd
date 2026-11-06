## Riassunto delle regole in italiano (finestra «Regole»).
class_name Regolamento
extends RefCounted


static func testo(m: Motore) -> String:
	var t: Array = []
	t.append("[font_size=24][b]Vijayanagara — regole in breve[/b][/font_size]")
	t.append("[b]Obiettivo.[/b] La partita finisce con l'invasione di Timur (seconda carta Timuride). Vince chi ha più punti vittoria; a parità contano le Risorse.")
	t.append("• [b]Sultanato di Delhi[/b]: Prosperità delle Province Tributarie, più 3 meno gli Invasori mongoli rimasti a Delhi alla fine (minimo −3).")
	t.append("• [b]Regno Bahmani[/b]: Prosperità delle Province che Controlla, più i Forti sulla mappa, più la sua Influenza nel Deccan.")
	t.append("• [b]Impero di Vijayanagara[/b]: Prosperità delle Province che Controlla, più i Templi sulla mappa, più la sua Influenza nel Deccan.")
	t.append("\n[b]Sequenza di gioco.[/b] Si scopre una carta. Le fazioni idonee, nell'ordine delle bandiere della carta, scelgono: [b]Comando e Decreto[/b] oppure [b]Evento o Comando[/b] (ciascuna casella una sola volta per carta), un [b]Comando Limitato[/b] (un solo spazio) oppure [b]Passa[/b] (+1 Risorsa, +3 al Sultanato). Chi ha usato una delle due caselle a forcella salta la carta successiva, salvo che abbia giocato un Evento «Resta idoneo».")
	t.append("Ogni Comando costa 1 Risorsa per spazio. Il Decreto si fa prima o dopo il Comando e non costa nulla.")
	t.append("\n[b]Mazzo.[/b] 24 Eventi in quattro pile; due Invasioni mongole in ciascuna delle prime tre, le due carte Timuridi nell'ultima; le tre Successioni fra le pile. Invasioni e Successioni non cambiano l'idoneità.")
	t.append("[b]Dinastie.[/b] Con i Khalji la Ribellione è vietata; la prima Successione porta i Tughlaq e la permette.")
	t.append("\n[b]Tributo e Controllo.[/b] All'inizio tutte le Province sono Tributarie. Una Provincia Indipendente è Controllata da chi vi ha più pezzi di tutti gli altri insieme. Emiri e Raja sono sempre Ribelli nelle Province della loro fazione; quando torna il Tributo diventano Obbedienti.")
	t.append("[b]Influenza nel Deccan[/b] (0–4): sale e scende con Eventi, Migrazioni e battaglie fra Bahmani e Vijayanagara. Salendo libera le Unità sul tracciato e potenzia Commercio, Cospira e Costringi; scendendo sotto una casella già svuotata vi riporta 2 Unità.")
	t.append("[b]Cavalleria[/b]: dopo i dadi, prima l'attaccante e poi il difensore possono spendere segnalini: [i]Carica[/i] abbassa di 1 un proprio dado, [i]Schermo[/i] toglie un dado avversario che non mostra 1. I Mongoli caricano sempre una volta.")
	t.append("[b]Battaglia[/b]: l'attaccante tira 4 dadi (3 contro i Bahmani con un Forte, 3 per i Mongoli a Delhi), il difensore 2. Ogni dado che, dopo la Cavalleria, non supera il numero delle proprie Unità coinvolte (massimo 5; il 6 manca sempre) è un colpo. Ognuno toglie i propri pezzi. Fra Bahmani e Vijayanagara chi perde meno pezzi guadagna 1 Influenza e l'altro la perde.")
	for f in ["D", "B", "V"]:
		t.append("\n[font_size=19][b]%s[/b][/font_size]" % m.nome_faz(f))
		t.append("[b]Comandi[/b]")
		for c in Regole.COMANDI[f]:
			t.append("• [b]%s[/b]: %s" % [m.nome_cmd(c), m.descrizione(c, f)])
		t.append("[b]Decreti[/b]")
		for d in Regole.DECRETI[f]:
			t.append("• [b]%s[/b]: %s" % [m.nome_cmd(d), m.descrizione(d, f)])
	t.append("\n[font_size=19][b]Invasioni mongole[/b][/font_size]")
	t.append("La fazione indicata (Bahmani o Vijayanagara) esegue due Comandi mongoli: [b]Ammassa[/b] (3 Invasori nei Passi montani; oltre 4 scendono nel Punjab, poi a Delhi), [b]Avanza[/b] (dai Passi al Punjab o dal Punjab a Delhi), [b]Attacca e saccheggia[/b] (battaglia contro il Sultanato nello spazio, poi per ogni Invasore rimasto: −1 Risorsa al Sultanato fino a un minimo di 3; nel Punjab anche −1 Truppa in una Provincia, a Delhi −2; oltre 3 Invasori tornano Disponibili). Poi può accettare i doni compromettenti: −1 Influenza per +2 Risorse e +2 Cavallerie.")
	t.append("[b]Timur[/b]: la prima carta Timuride porta metà degli Invasori Disponibili nei Passi montani; la seconda scatena l'attacco ai Passi, al Punjab e a Delhi fino all'ultimo uomo, poi si contano i punti.")
	t.append("\n[b]Interfaccia.[/b] Ogni decisione è una domanda nel pannello a destra: rispondi con i tasti o cliccando sugli spazi evidenziati. Passa il mouse su uno spazio per vederne il contenuto; clicca la carta per ingrandirla. «Annulla» torna indietro di una decisione (solo nelle partite locali). La partita si salva da sola su questo dispositivo dopo ogni atto e ogni quattro atti anche online.")
	return "\n".join(t)
