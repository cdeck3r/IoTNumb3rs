---
description: >-
  Aufrüsten der numb3rspipeline mit neuen Funktionen für eine verbesserte
  Datenerfassung
---

# Sprint: numb3rspipeline

## Sprint Details

#### Ziele 

* Höherer Automatisierungsgrad bei der Datenerfassung durch Projektmitglieder
* Automatische Sicherung der erfassten Daten in gemeinsamer Datenbasis
* Statistik-Kennzahlen über den Umfang der Datenbasis

#### Zeitraum

Start: 26.10.2018  
Ende: 13.11.2018

## Neue Funktionen der numb3rspipeline

numb3rspipeline ist ein Instrument für die Erfassung von Daten aus IoT Infografiken. Nach den Erfahrungen im initialen Sprint wurde die numb3rspipeline um neue Funktionen ergänzt.

* **Homepage URL:** um den Kontext der IoT Inforgraphik zu erfassen, wird zusätzlich die Webseite, von der die Infographik kommt, erfasst. Die URL wird in der Datei 

  `url_filelist.csv`zur jeweiligen Infograpfik URL erfasst.

* **Automatishce Erstellung von Ethercalc Dokumenten:** Nach der Vorverarbeitung der Infografik, werden die Basisdaten, z.B. URL, filename, homepage URL, Nutzer, in einem automatisch generierten [Ethercalc Dokument](https://www.ethercalc.org/) persistiert.
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

## Nutzung der numb3rspipeline

Mit den neuen Funktionen hat sich Nutzung vereinfacht.

1. **\[Bildersuche\]** IoT Infografiken mit Google Bildersuche finden
2. URLs der **Bilddateien** und URLs der Homepage, von der die Bilddatei stammt, speichern in Datei `url_list.txt`

   Format: `<url>;<homepage_url>`

3. **\[DROPBOX, Upload-Link\]** `url_list.txt` auf Dropbox kopieren. Link zum Hochladen in separater Mail zu Beginn des Projektes mitgeteilt.
4. **\[Analyselauf numb3rspipeline\]** _... pipeline läuft..._ nichts zu tun ... warten.
   1. Status des Analyselaufs wird in Slack gepostet
   2. Für jede Infografik URL wird eine Ethercalc URL in Slack gepostet
5. **\[DROPBOX, Download-Link\]** Ein neues Verzeichnis in dem Format `[yyyymmdd-hhmm]` wurde angelegt. Für jede URL aus `url_list.txt` liegt in diesem Verzeichnis nun eine Bild- und Textdatei. Dateien können über den Download-Link  zugegriffen werden.

   1. `file<n>_<bildname>`
   2. `file<n>_<bildname>.txt`
   3. `url_filelist.csv`

   Die Datei `url_filelist.csv` enthält nach dem Analyselauf für alle URLs aus der `url_list.txt` die Homepage URL und die Ethercalc URL für das generierte Dokument zur Datenerfassung.

6. **\[Erfassung der Daten mit Ethercalc\]** Nach dem Analyselauf wird für jede Infografik ein Ethercalc Dokument erzeugt. Darin sind die Grunddaten wie Infografik URL, filename, homepage\_url in einer Standardmaske für die Datenerfassung enthalten. Die URLs sind in `url_filelist.csv`enthalten und werden nach jedem Analyselauf in Slack  gepostet. **Für die Erfassung soll für jede Infografik das jeweils erzeugte Ethercalc Dokument verwendet werden.**
   1. Daten aus Bilddatei `file<n>_<bildname>`_\(URL zur Infografik in Ethercalc Dokument enthalten\)_ manuell extrahieren und gemäß Vorlage in das entsprechend generierte Ethercalc Dokument eintragen
   2. _Optional:_ Keyword-Suche in Textdatei `file<n>_<bildname>.txt`
7. **\[Automatisches Backup und Statistik\]** Die erfassten Daten in den Ethercalc Dokumenten werden regelmäßig gesichert. Für den Nutzer nichts zu tun.  
   1. Daten: [https://github.com/cdeck3r/IoTNumb3rs/tree/iotdata](https://github.com/cdeck3r/IoTNumb3rs/tree/iotdata)
   2. `stats.csv`: Statistik Informationen über die bisher erfassten Daten für jeden Nutzer

