ARBORILIEVI – Web app per sopralluoghi arborei

FUNZIONI
- Scatto foto dalla fotocamera o selezione dalla galleria.
- Scelta specie dall'elenco (46 voci) o inserimento libero.
- Rilevamento GPS ad alta precisione richiesta (coordinate WGS84 + accuratezza dichiarata dal dispositivo).
- Inserimento codice albero, stato vegetativo, altezza, circonferenza e note.
- Archivio locale, modifica ed eliminazione delle schede.
- Mappa OpenStreetMap (Internet richiesto per la mappa).
- Esportazione CSV compatibile Excel, GeoJSON per QGIS, backup JSON con fotografie, importazione backup.
- App installabile sul telefono come PWA e utilizzabile offline dopo la prima visita (eccetto cartografia).

COME AVVIARLA
La fotocamera e soprattutto la geolocalizzazione richiedono un contesto sicuro (HTTPS o localhost).
1. Caricare TUTTI i file della cartella su un hosting statico HTTPS, come GitHub Pages, Netlify o Vercel.
2. Aprire l'indirizzo HTTPS con Chrome o Safari dello smartphone.
3. Consentire accesso a fotocamera/foto e posizione quando richiesto.
4. Su iPhone, usare Safari > Condividi > Aggiungi alla schermata Home.
   Su Android, usare Chrome > menu > Installa app / Aggiungi a schermata Home.
5. Il primo avvio necessita di Internet per caricare le risorse; per la mappa serve Internet.

PROVA SU PC
Per visualizzare in locale, nella cartella eseguire: python -m http.server 8000
Poi aprire http://localhost:8000 (su localhost il GPS può funzionare se il PC ha accesso alla geolocalizzazione).
Non aprire direttamente index.html come file:// se vuoi provare il GPS.

ARCHIVIAZIONE E PRIVACY
Tutti i rilievi e le foto sono conservati nel browser del dispositivo tramite IndexedDB: nessun server, nessun account, nessuna sincronizzazione automatica. Fai backup JSON periodici. Foto ridimensionate a max 1600px e convertite in JPEG per contenere l'occupazione.
Le mappe caricano tasselli dalla rete OpenStreetMap e Leaflet da CDN; questo comporta richieste a servizi esterni quando la mappa è usata.
La precisione GPS dipende dallo smartphone, dall'ambiente e dai permessi; non sostituisce un rilievo topografico.

VERSIONE: 1.0
