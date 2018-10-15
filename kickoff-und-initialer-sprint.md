---
description: Kickoff des Projekts und zum ersten Mal mit der numb3spipeline arbeiten.
---

# Kickoff und Initialer Sprint

## Kickoff

* Erläuterung des Projektumfelds
* Projektrollen und -steuerung
* Tools und Services

## Initialer Sprint

#### Nutzen

* Der Sprint soll die Funktion der numb3rspipeline unter Realbedingungen des Projekts testen.
* Die Teammitglieder sollen mit der beschriebenen Vorgehensweise vertraut werden.
* Probleme im Zusammenspiel zwischen Team und numb3rspipeline sowie Verbesserungen sollen identifiziert werden.

#### Ziel

Jedes Teammitglied analysiert mind. 3 IoT Infografiken.

#### Umgang mit Dropbox

Die Dropbox Freigabe ist schwierig. Ursprünglich war geplant, dass jedes Teammitglied einen Folder über Dropbox freigegeben bekommt. Darüber wird mit der numb3rspipeline interagiert. Es kann jedoch kein Folder unterhalb des Apps Folders zum gemeinsamen Austausch freigegeben werden. Der Apps Folder wurde vom Dropbox API angelegt. Die File Interaktionen via des Dropbox API sind auf diesen Folder beschränkt. Eine weitere Konsequenz ist, dass man keinen Subfolder des Apps Folder  für gemeinsamen Arbeiten mit anderen Dropbox Nutzern freigeben kann. Daher folgendes Vorgehen:

1. Funktion "Dateien anfordern": Dropbox erstellt einen Link über den Dateien in entsprechenden Folder von Users gelegt werden können. Hierbei können Folder unterhalb des Apps Folders angegeben werden. Das ist der **Upload-Link**.
2. Funktion "Ordner freigeben": Dropbox erstellt einen Link, der ansehen und runterladen erlaubt. Das ist der **Download-Link**.

#### Vorgehen im Sprint

1. IoT Infografiken mit Google Bildersuche finden
2. URLs der **Bilddateien** speichern in Datei `url_list.txt`
3. **\[DROPBOX, Upload-Link\]** `url_list.txt` auf Dropbox kopieren. Link zum Hochladen in separater Mail erhalten.
4. _... numb3rspipeline läuft..._ nichts zu tun, warten.
5. **\[DROPBOX, Download-Link\]** Für jede URL aus url\_list.txt wurde nun eine Bild- und Textdatei angelegt. Dateien können über den Download-Link  zugegriffen werden.
   1. `file<n>_<bildname>`
   2. `file<n>_<bildname>.txt`
6. Keyword-Suche in Textdatei `file<n>_<bildname>.txt`
7. Erfassung der Daten in Ethercalc
   1. Vorlage: [https://ethercalc.org/llbkbe1n62vh](https://ethercalc.org/llbkbe1n62vh)
   2. Neues ethercalc erstellen: [https://ethercalc.org/](https://ethercalc.org/) --&gt; Create Spreadsheet
   3. Daten aus Bilddatei `file<n>_<bildname>`manuell extrahieren und gemäß Vorlage in neues ethercalc Spreadsheet eintragen
8. Ethercalc URL kopieren und über Teamleiter gesammelt an C. Decker schicken

## Ergebnisse & Lessons learnt

In diesem Sprint sollte die Praxistauglichkeit der numb3rspipeline getestet werden.

#### numb3rspipeline: Probleme und Lösungen

* Beim Hochladen der Datei `url_list.txt` wird der Datei der Username vorangestellt. numb3rspipeline wurde angepasst, und kann nun mit dem veränderten usernamen umgehen.
* Die URLs enthalten jeweils ein `<CR>` Zeichen am Ende der Zeile. Das verursacht Fehler beim Runterladen der Bilder via `curl`. Das URL parsing wurde angepasst. 
* Leerzeilen in der `url_list.txt` werden als leere URLs interpretiert. Es wird kein File erzeugt, aber der file counter `<n>` weitergezählt. Wird nicht behandelt. Verhalten der numb3rspipeline bleibt bestehen.

#### Empfehlungen ans Team

* URLs in `url_list.txt`, die nicht auf einen Filenamen enden, können nicht verarbeitet werden. Wird nicht behandelt. Verhalten der numb3rspipeline bleibt bestehen.  Empfehlung: URLs verwenden, die auf Dateinamen enden.
* Bilder, die aus der Vorschau der Google Bildersuche entnommen werden, haben einen schlechte Qualität für die Texterkennung.  Empfehlung: Bild der Originalseite angeben.
* URLs, die nicht in einer Datei `url_list.txt` stehen, können nicht verarbeitet werden. Empfehlung: URLs immer nur in `url_list.txt` speichern.

#### Erzielter Wert

numb3rspipeline kann mit vom Team erstellen `url_list.txt` Dateien umgehen.

#### Nächste Schritte

Folgende Verbesserungen der numb3rspipeline sind vorgesehen.

* numb3rspipeline integriert Keyword Suche
* automatische Erstellung des ethercalc Spreadsheet durch numb3rspipeline



