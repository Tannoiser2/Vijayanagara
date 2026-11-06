# Contenuto in italiano delle carte azione dei bot (dalle carte originali Non-Player).
PESCA="pesca un'altra carta azione"
RIMESC="rimescola il mazzo azioni e pesca"
def dec(*o): return ('box',[('b','Scegli 1 Decreto:',0)]+[('r',x,18) for x in o])
def cmd(*o): return ('box',[('r',x,0) for x in o])
def ramo(t,*o): return ('ramo',t,[('r',x,0) for x in o])
RIB="(A) {b}Ribellione{/b} con le priorità «Togli il Tributo»"
RIB2="(A) {b}Ribellione{/b} con Prosperità 2+ («Togli il Tributo»)"
RAD_V="{b}Raduno{/b} con le priorità «Piazza Raja»"
RAD_B="{b}Raduno{/b} con le priorità «Piazza Emiri»"
MIG_V="{b}Migrazione{/b} in fino a 3 spazi con le priorità di Movimento; sposta l'Influenza nella prima destinazione con un pezzo {B}"
MIG_B="{b}Migrazione{/b} in fino a 3 spazi con le priorità di Movimento; sposta l'Influenza nella prima destinazione con un pezzo {V}"
ATT_V="{b}Attacco{/b} negli spazi con 3+ Raja: bersaglio Governatore, poi la Fazione del giocatore, poi {B}, poi {D}. Rinforzo di 1 Raja dal Tempio adiacente con più Raja."
ATT_B="{b}Attacco{/b} negli spazi con 2+ Emiri: bersaglio Governatore, poi la Fazione del giocatore, poi {V}, poi {D}. Rinforzo di 2 Emiri dal Forte adiacente con più Emiri."
COMP="{b}Costringi{/b}: 1) se {D} è un giocatore, per togliere un Governatore; 2) con le priorità «Costringi»"
BUILD_V="{b}Costruisci{/b} con le priorità «Piazza Tempio»"
BUILD_B="{b}Costruisci{/b} con le priorità «Piazza Forte»"
ATT_D="{b}Attacco{/b} negli spazi con 2+ Unità {D}: bersaglio la Fazione del giocatore, poi quella con più punti. Rinforzo di 2 Unità dalla Qasbah adiacente con più Unità."
GOV="{b}Governa{/b}: 1) per togliere Unità obbedienti (e piazzare Qasbah se possibile); 2) per piazzare Qasbah; 3) nelle Province con le priorità «Piazza Governatori»"
CAMP="{b}Campagna{/b} con le priorità di Movimento in fino a tre destinazioni, una alla volta, considerando adiacenti tutti gli spazi. Ogni pezzo si sposta una volta sola."
DEC_D=["(A) {b}Esigi obbedienza{/b}","(B) {b}Riscuoti tributi{/b}"]
C={
'I':('V',[('q',"Il tiro di 2d6 non supera i Raja Disponibili?",PESCA),dec("(A) Raja in 4+ Province? "+BUILD_V,"(B) "+COMP,"(C) {b}Tassa{/b}"),cmd(RIB,"(B) "+RAD_V),('stop',)]),
'JJ':('V',[dec("(A) "+BUILD_V,"(B) 2+ Raja Disponibili? "+COMP,"(C) {b}Tassa{/b}"),('q',"Dinastia Khalji?"),ramo('SÌ',"(A) "+MIG_V,"(B) "+RAD_V),ramo('NO',RIB,"(B) "+ATT_V,"(C) "+MIG_V),('stop',)]),
'K':('V',[('q',"Il tiro di 2d6 non supera i Raja Disponibili?",PESCA),dec("(A) {IV} 2+? "+COMP,"(B) "+BUILD_V,"(C) {b}Tassa{/b}"),cmd(RIB,"(B) "+RAD_V),('stop',)]),
'KK':('V',[dec("(A) Costringi può togliere un Governatore? "+COMP,"(B) "+BUILD_V,"(C) {b}Tassa{/b}"),('q',"2+ Province con 3+ Raja e pezzi avversari?"),ramo('SÌ',RIB2,"(B) "+ATT_V,"(C) "+MIG_V),ramo('NO',RIB,"(B) "+MIG_V+"; se {IV} è meno di 3, la prima destinazione deve avere un pezzo {B}","(C) "+RAD_V),('stop',)]),
'L':('V',[('q',"{IV} meno di 2?",PESCA),dec("(A) 2+ Raja Disponibili? {b}Costringi{/b}: 1) nella Provincia con meno pezzi {B} (almeno 1); 2) con le priorità «Costringi»","(B) "+BUILD_V,"(C) {b}Tassa{/b}"),('q',"Il tiro di 3d6 non supera i Raja Disponibili?"),ramo('SÌ',RAD_V),ramo('NO',RIB2,"(B) "+ATT_V,"(C) "+MIG_V),('stop',)]),
'LL':('V',[dec("(A) "+BUILD_V,"(B) 2+ Raja Disponibili? "+COMP,"(C) {b}Tassa{/b}"),('q',"Il tiro di 2d6 non supera i Raja Disponibili?"),ramo('SÌ',RIB,"(B) "+RAD_V),ramo('NO',RIB,"(B) "+ATT_V,"(C) "+MIG_V),('stop',)]),
'M':('V',[('q',"7+ Raja in una sola Provincia?",PESCA),cmd(RIB2,"(B) "+MIG_V,"(C) "+RAD_V),dec("(A) "+BUILD_V,"(B) 2+ Raja Disponibili? "+COMP,"(C) {b}Tassa{/b}"),('stop',)]),
'MM':('V',[dec("(A) 2+ Raja Disponibili? "+COMP,"(B) "+BUILD_V,"(C) {b}Tassa{/b}"),('q',"Il tiro di 2d6 non supera i Raja Disponibili?"),ramo('SÌ',RIB,"(B) "+RAD_V),ramo('NO',RIB,"(B) "+ATT_V,"(C) "+MIG_V),('stop',)]),
'E':('B',[('q',"Il tiro di 1d6 non supera gli Emiri Disponibili?",PESCA),dec("(A) {b}Cospira{/b} per sostituire almeno un Governatore","(B) "+BUILD_B,"(C) {b}Commercio{/b}"),cmd(RIB,"(B) "+RAD_B,"(C) "+ATT_B),('stop',)]),
'EE':('B',[cmd(RIB,"(B) "+MIG_B),dec("(A) {b}Cospira{/b} per sostituire o togliere due Governatori","(B) "+BUILD_B,"(C) {b}Commercio{/b}"),('stop',)]),
'F':('B',[('q',"4+ Emiri in una sola Provincia?",PESCA),dec("(A) {b}Cospira{/b} per sostituire 2 Governatori con Emiri Disponibili","(B) "+BUILD_B,"(C) {b}Commercio{/b}"),('q',"{IB} 2 o più?"),ramo('SÌ',RIB,"(B) "+ATT_B,"(C) "+RAD_B),ramo('NO',RIB2,"(B) "+MIG_B,"(C) "+RAD_B),('stop',)]),
'FF':('B',[('q',"Il tiro di 1d6 non supera gli Emiri Disponibili?"),ramo('SÌ',RIB,"(B) "+RAD_B),ramo('NO',RIB,"(B) "+MIG_B),dec("(A) {b}Cospira{/b} per sostituire due Governatori/Raja","(B) "+BUILD_B,"(C) {b}Commercio{/b}"),('stop',)]),
'G':('B',[('q',"Il tiro di 1d6 non supera gli Emiri Disponibili?",PESCA),dec("(A) {b}Cospira{/b} per sostituire due Governatori","(B) "+BUILD_B,"(C) {b}Commercio{/b}"),cmd(RIB,"(B) "+RAD_B),('stop',)]),
'GG':('B',[dec("(A) "+BUILD_B,"(B) {b}Cospira{/b} per sostituire almeno 1 Governatore con un Emiro Disponibile","(C) {b}Commercio{/b}"),cmd(RIB,"(B) "+MIG_B),('stop',)]),
'H':('B',[('q',"{IB} meno di 2?",PESCA),dec("(A) "+BUILD_B,"(B) {b}Cospira{/b}","(C) {b}Commercio{/b}"),('q',"Il tiro di 1d6 non supera gli Emiri Disponibili?"),ramo('SÌ',RIB2,"(B) "+RAD_B),ramo('NO',RIB,"(B) "+ATT_B,"(C) "+MIG_B),('stop',)]),
'HH':('B',[dec("(A) {b}Cospira{/b} per sostituire 2 Governatori/Raja con Emiri Disponibili","(B) "+BUILD_B,"(C) {b}Commercio{/b}"),('q',"Il tiro di 1d6 non supera gli Emiri Disponibili?"),ramo('SÌ',RIB,"(B) "+RAD_B),ramo('NO',RIB,"(B) "+MIG_B,"(C) "+ATT_B),('stop',)]),
'A':('D',[('q',"6 + 2d6 non supera le Truppe Disponibili?"),ramo('SÌ',"Risorse meno di 16? Scegli 1 Decreto: "+" ".join(DEC_D),"{b}Coscrizione{/b} in fino a 6 spazi con le priorità «Piazza Truppe»"),('q',"(NO) 2+ Governatori nelle Province Indipendenti (o adiacenti) a 2+ di esse?",PESCA),ramo('SÌ',"{b}Marcia{/b} in fino a 4 spazi: 1) verso Province Indipendenti; 2) con le priorità di Movimento"),dec(*["Se non già scelto sopra:"]+DEC_D),('stop',)]),
'AA':('D',[('q',"2+ spazi con 2+ Unità {D} e Mongoli o Unità ribelli?",RIMESC),cmd(ATT_D),dec(*DEC_D),('stop',)]),
'B':('D',[('q',"3+ Invasori mongoli sulla mappa?",PESCA),('q',"9+ Truppe in uno spazio?",RIMESC),dec("(A) "+CAMP),cmd("(A) "+ATT_D,"(B) "+GOV),('stop',)]),
'BB':('D',[('q',"3+ Governatori Disponibili e «I signori del Deccan» non ancora giocata?"),ramo('NO',"2+ Province con Unità obbedienti e un Governatore? Se no: "+RIMESC),dec(*["Risorse meno di 16?"]+DEC_D),cmd(GOV),dec(*["Se non già scelto sopra:"]+DEC_D),('stop',)]),
'C':('D',[('q',"Il tiro di 3d6 non supera le Truppe Disponibili?"),ramo('SÌ',"Risorse meno di 16? Scegli 1 Decreto: "+" ".join(DEC_D),"{b}Coscrizione{/b} in fino a 6 spazi con le priorità «Piazza Truppe»"),('q',"(NO) 3+ Governatori Disponibili, oppure 2+ Province con Unità obbedienti e un Governatore?",PESCA),ramo('SÌ',GOV),dec(*["Se non già scelto sopra:"]+DEC_D),('stop',)]),
'CC':('D',[('q',"2+ Governatori nelle Province Indipendenti (o adiacenti) a 2+ di esse?"),ramo('SÌ',"{b}Marcia{/b} in fino a 4 spazi: 1) verso Province Indipendenti; 2) con le priorità di Movimento. Poi scegli 1 Decreto: "+" ".join(DEC_D)),('q',"(NO) 2+ spazi con 2+ Unità {D} e Invasori mongoli o Unità ribelli?",RIMESC),ramo('SÌ',"Decreto {b}Riscuoti tributi{/b}, poi "+ATT_D),('stop',)]),
'D':('D',[('q',"Risorse più di 12 e 9+ Truppe in uno spazio?",PESCA),dec("(A) "+CAMP),cmd("(A) "+ATT_D,"(B) "+GOV),('stop',)]),
'DD':('D',[('q',"Il tiro di 3d6 non supera le Truppe Disponibili?"),ramo('SÌ',"Risorse meno di 16? Scegli 1 Decreto: "+" ".join(DEC_D),"{b}Coscrizione{/b} in fino a 6 spazi con le priorità «Piazza Truppe»"),('q',"(NO) 3+ Governatori Disponibili, oppure 2+ Province con Unità obbedienti e un Governatore?",RIMESC),ramo('SÌ',GOV),dec(*["Se non già scelto sopra:"]+DEC_D),('stop',)]),
'O':('M',[('q',"Restano 2 Comandi?","usa la carta OO"),('q',"Avanzando ci sarebbero almeno 3 Mongoli più delle Truppe a Delhi?"),ramo('SÌ',"{b}Avanza{/b}, poi {b}Attacca{/b} a Delhi (3 dadi)."),('q',"(NO) Avanzando ci sarebbero almeno 3 Mongoli più delle Truppe nel Punjab?","usa la carta OO"),ramo('SÌ',"{b}Avanza{/b}, poi {b}Attacca{/b} nel Punjab.")]),
'OO':('M',[('q',"Uno spazio con 4 o più Mongoli e 2 Truppe o meno?"),ramo('SÌ',"{b}Attacca{/b} in uno di quegli spazi: prima Delhi, poi il Punjab, poi i Passi montani se le Risorse {D} sono 7 o più."),('q',"(NO) 1d6 meno dei Mongoli a Delhi?"),ramo('SÌ',"{b}Attacca{/b} a Delhi (3 dadi)."),('q',"(NO) 1d6 meno dei Mongoli nel Punjab?"),ramo('SÌ',"{b}Attacca{/b} nel Punjab."),('q',"(NO) 1d6 meno dei Mongoli nei Passi montani e Risorse {D} 7 o più?"),ramo('SÌ',"{b}Attacca{/b} nei Passi montani."),ramo('NO',"{b}Ammassa{/b} se possibile, altrimenti torna all'inizio.")]),
}
