# ArboRilievi Cloud – guida GitHub Pages e Supabase

## 1. Cosa comprende

Web app per operatori (creazione/modifica di aree, alberi/palme, filari, fotografie, GPS) e Comune/DEC (sola lettura, dashboard, mappa, esportazioni). Dati condivisi in Supabase, accessibili da PC, iPhone e Android con login email/password. Il codice web è pubblico su GitHub Pages, **i dati e le foto sono privati in Supabase** con politiche RLS. Questo pacchetto non contiene credenziali.

## 2. Crea il database Supabase

1. Apri https://supabase.com/dashboard, registrati ed entra in un **nuovo progetto**.
2. Dal progetto apri **SQL Editor** → **New query**; incolla tutto il contenuto del file `schema.sql`; clicca **Run**. Esegui su un progetto nuovo, non su un database contenente già dati.
3. Apri **Authentication → Providers → Email** e verifica che Email sia abilitato. Per accesso riservato, disattiva la registrazione libera (**Allow new users to sign up**, se presente) e crea gli utenti come amministratore da **Authentication → Users → Add user**. Non pubblicare le loro password.
4. Crea almeno tre utenti (uno per te/amministratore, un rilevatore, uno del Comune). Il trigger SQL crea di norma automaticamente un profilo iniziale `viewer`. Se un utente è stato creato prima del trigger, inserisci un profilo dalla console SQL.
5. In **SQL Editor** esegui per ogni utente (usando l'UUID effettivo visibile in Authentication → Users):

```sql
update public.profiles
set role = 'admin', display_name = 'Responsabile censimento'
where id = 'UUID_AMMINISTRATORE';

update public.profiles
set role = 'surveyor', display_name = 'Rilevatore'
where id = 'UUID_RILEVATORE';

update public.profiles
set role = 'viewer', display_name = 'Comune / DEC'
where id = 'UUID_UTENTE_COMUNE';
```

I ruoli sono gestiti solo da SQL Editor e **non** sono modificabili dalla web app. Il Comune in ruolo `viewer` può leggere ed esportare, non inserire, modificare o cancellare. La cancellazione dal client è disabilitata anche per i rilevatori, per conservare la cronologia.

## 3. Collega il sito al database

1. In Supabase trova **Project URL** e la chiave **publishable** (oppure la precedente `anon`) nel pannello **Project Settings → API Keys** (la posizione del menu può cambiare).
2. Apri il file `config.js` con un editor di testo e sostituisci i due valori segnaposto.
3. **Inserisci solo la chiave pubblicabile/anon**. Mai `service_role`, `secret`, password, credenziali di gestione o token personali: GitHub Pages è pubblico.
4. Le protezioni reali dipendono dalle policy RLS già incluse nello schema SQL: non disattivarle.

## 4. Aggiorna il repository GitHub Pages

1. Estrai lo ZIP sul computer.
2. Apri https://github.com/ivangiuliolagalante-ui/arborilievi.
3. Nel repository usa **Add file → Upload files** e carica **tutti i file** presenti nella cartella estratta, compresi `shapefile.js`, `schema.sql`, `config.js`, `index.html` e `sw.js`, direttamente nella directory principale.
4. Conferma con **Commit changes**. I file omonimi vengono aggiornati dal nuovo commit; non occorre cancellare il repository. Se GitHub segnala conflitti, verifica che i file si trovino nella root.
5. In **Settings → Pages** imposta **Deploy from a branch**, scegli il ramo usato nel repository (per esempio `main` oppure `principale`) e `/(root)`, quindi **Save**.
6. L'indirizzo dell'app dovrebbe essere: https://ivangiuliolagalante-ui.github.io/arborilievi/ (sostituire il nome utente se diverso).
7. Effettua l'accesso con un account `surveyor`, crea prima un'area e poi un albero di prova. Verifica il salvataggio. Accedi con `viewer` e verifica che non siano disponibili pulsanti di modifica ma funzionino visualizzazione/esportazione.

**Nota:** GitHub Pages non esegue il backend: autenticazione, database e archivio foto risiedono in Supabase. Il repository va mantenuto privo di segreti e dati personali. Prima di impiegare il sistema per dati istituzionali, verificare con il Comune le autorizzazioni, la titolarità, la localizzazione dei dati, il contratto/DPA e le misure privacy.

## 5. Esportazione ESRI Shapefile EPSG:7792

Dal pannello **Esporta** premi **Shapefile EPSG:7792 (.zip)**. Il pacchetto contiene:

- `alberi_palme/` (POINT): `.shp`, `.shx`, `.dbf`, `.prj`, `.cpg`;
- `aree_verdi/` (POLYGON): gli stessi cinque file;
- `elementi_lineari/` (POLYLINE): gli stessi cinque file;
- `dizionario_campi.csv` (corrispondenza campo DBF → campo app);
- `esclusi_senza_geometria.csv` (record senza geometria idonea);
- `LEGGIMI.txt` (avvertenze e conteggi).

Le coordinate degli alberi derivano da longitudine/latitudine GPS (WGS84). Le aree richiedono un poligono GeoJSON, i filari una polilinea GeoJSON; se una geometria manca, l'elemento **non** viene inventato: è elencato tra gli esclusi. La conversione da WGS84 a RDN2008/UTM33N EPSG:7792 è una conversione con ipotesi di trasformazione nulla, da **validare** in QGIS/GIS per conformità metrica e geodetica.

Il modulo di esportazione usa due librerie JavaScript CDN (`proj4`, `JSZip`) e quindi richiede connessione quando queste non sono già in cache. La Web App non può assicurare accuratezza 1:500 con il solo GPS dello smartphone; per la consegna contrattuale servono rilievo/controllo GNSS appropriato, validazione topologica e verifica con il censimento originario (Elaborato 4). In particolare non vengono generati poligoni da una semplice superficie in m².

Lo Shapefile ha nomi campi massimo 10 caratteri e testi limitati a 254/255 byte: per il dato completo usare anche **CSV/JSON**. Le foto **non** sono incluse nello ZIP Shapefile, rimangono accessibili separatamente nel bucket privato. Il formato Linfa e i PDF cartografici richiedono ulteriori procedure di consegna concordate col DEC.

## 6. Sicurezza e operatività

- Non condividere l'account del Comune con i rilevatori.
- Il pulsante **Aggiorna** rilegge i dati dal cloud (non è un aggiornamento automatico istantaneo).
- Nelle versioni attuali è richiesta connessione per inserimento e salvataggio: non è ancora implementata una coda offline sicura con sincronizzazione.
- Le segnalazioni di classe C-D/D e rischio imminente devono essere inviate al DEC con modalità e tempi previsti dal protocollo: il salvataggio in app non equivale alla comunicazione.
- Esegui backup periodici e valuta le impostazioni di ripristino nel progetto Supabase.
- Per il conteggio dell'avanzamento il riferimento di 295 aree proviene dal protocollo: la corrispondenza delle aree con l'Elaborato 4 deve essere verificata e importata prima di usare la percentuale come indicatore ufficiale.

## 7. Collaudo consigliato

1. Con ruolo `surveyor`, crea un'area con codice univoco e fotografia.
2. Crea un albero nell'area, registra GPS/foto/scheda.
3. Accedi con ruolo `viewer` da un secondo dispositivo, clicca **Aggiorna** e apri i dettagli.
4. Esporta Shapefile, apri in QGIS: verifica CRS EPSG:7792, coordinate e contenuto DBF.
5. Esporta il JSON e CSV per confrontare numero record e campi.
6. Prova con una seconda area dotata di geometria GeoJSON Polygon e un filare LineString, verificando i rispettivi layer.

**Conformità:** si tratta di una piattaforma operativa preliminare; prima di una consegna ufficiale occorre collaudo tecnico, GIS e privacy.
