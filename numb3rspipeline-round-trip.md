---
description: numb3rspipeline wurde weiterentwickelt und um weitere Funktionen ergänzt.
---

# numb3rspipeline: round trip

## Neue Funktionen der numb3rspipeline

Nach den Erfahrungen im initialen Sprint wurde die numb3rspipeline um neue Funktionen ergänzt.

* **Homepage URL:** um den Kontext der IoT Inforgraphik zu erfassen, wird zusätzlich die Webseite, von der die Infographik kommt, erfasst. Die URL wird in der Datei 

  `url_filelist.csv`zur jeweiligen Infograpfik URL erfasst.

* **Erstellung von Ethercalc Dokumenten:** Nach der Vorverarbeitung der Infografik, werden die Basisdaten, z.B. URL, filename, homepage URL, Nutzer, in einem automatisch generierten [Ethercalc Dokument](https://www.ethercalc.org/) persistiert.
* **Ethercalc URLs:** 
  * Die URLs zu den generierten Ethercalc Dokumenten werden in der Datei `url_filelist.csv` abgespeichert.
  * Zusätzlich werden die URLs im Slack Channel publiziert.
* **Backup:** Alle generierten Ethercalc URLs werden nachts als `.csv, .xlxs, .md` heruntergeladen. Die Dateien werden im GitHub Repo gespeichert: [https://github.com/cdeck3r/IoTNumb3rs/tree/iotdata](https://github.com/cdeck3r/IoTNumb3rs/tree/iotdata)
* **Performance Statistik:** Die .csv Dateien mit den Daten aus den jeweiligen Ethercalc Dokumenten werden statistisch ausgewertet, um den bisher erfassten Datenumfang zu beschreiben.
  * Format: `datetime;user;total_rows;distinct_infographics`
  * `datetime`: Zeitstempel, yyyy-mm-dd HH:mm:ss
  * `user`: Dropbox Nutzername 
  * `total_rows`: Anzahl aller Datensätze eines Nutzers
  * `distinct_infographics`: Anzahl verschiedener Infographik URLs eines Nutzers
* **Neue Cronjobs:** regelmäßigen Ausführung der Funktionen
  * 9, 12, 15, 18, 21, 0 Uhr: Akquise und Auswertung von IoT Infografiken
  * 3, 6 Uhr: Backup der Daten und Berechnung der Performance Statistik
* **Bugfixing:** verschiedene kleinere Fehler

## Vorgehen und Nutzung

Mit den neuen Funktionen hat sich Nutzung vereinfacht.

1. IoT Infografiken mit Google Bildersuche finden
2. URLs der **Bilddateien** und URLs der Homepage, von der die Bilddatei stammt, speichern in Datei `url_list.txt`

   Format: `<url>;<homepage_url>`

3. **\[DROPBOX, Upload-Link\]** `url_list.txt` auf Dropbox kopieren. Link zum Hochladen in separater Mail erhalten.
4. **\[Durchlauf numb3rspipeline\]** _... pipeline läuft..._ nichts zu tun ... warten.
5. **\[DROPBOX, Download-Link\]** Ein neues Verzeichnis in dem Format `[yyyymmdd-hhmm]` wurde angelegt. Für jede URL aus `url_list.txt` liegt in diesem Verzeichnis nun eine Bild- und Textdatei. Dateien können über den Download-Link  zugegriffen werden.
   1. `file<n>_<bildname>`
   2. `file<n>_<bildname>.txt`
   3. `url_filelist.csv`
6. Die Datei `url_filelist.csv` enthält nach dem Durchlauf sind für alle URLs aus `url_list.txt` die Homepage URL und die Ethercalc URL für das generierte Dokument zur Datenerfassung 
7. Keyword-Suche in Textdatei `file<n>_<bildname>.txt`
8. Erfassung der Daten in Ethercalc
   1. Vorlage: [https://ethercalc.org/llbkbe1n62vh](https://ethercalc.org/llbkbe1n62vh)
   2. Neues ethercalc erstellen: [https://ethercalc.org/](https://ethercalc.org/) --&gt; Create Spreadsheet
   3. Daten aus Bilddatei `file<n>_<bildname>`manuell extrahieren und gemäß Vorlage in neues ethercalc Spreadsheet eintragen
9. Ethercalc URL kopieren und über Teamleiter gesammelt an C. Decker schicken

