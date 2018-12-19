---
description: Tiefere Einblicke aus den IoTNumb3rs Daten gewinnen
---

# Sprint: Dateneinblicke 

## Ziel

Neue Einblicke aus den IoTNumb3rs Daten gewinnen

## Messbare Resultate

* Jeder Nutzer erfasst 25 neue Infografiken.
* Am Ende des Sprints sind insgesamt, d.h. über alle Nutzer zusammen, mindestens 100 neue Datensätze hinzugekommen.
* Am Ende des Sprints ist die [Datenqualität](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md) >95%
* Die im Sprint [Datenqualitätsoffensive](sprint-datenqualitaetsoffensive.md) erstellten Leistungsstatistiken sind mit neuen Daten des Sprints fortgeschrieben.
* Die im Sprint [Datenqualitätsoffensive](sprint-datenqualitaetsoffensive.md) erstellten Boxplot Diagramme erhalten ein Update mit neuen IoTNumb3rs Daten.
* Es sind 4 neue Klassen von Boxplot-Diagramme erstellt, die in die Daten reinbohren, sog. Drill-Down.
* Es sind 2 neue Diagramme zur Erfüllung von Prognosen und zum Prognosehorizont erstellt.
* Für jeder Nutzer gibt es am Sprintende 1 Excelfile und 1 PDF File, in dem alle Diagramme enthalten sind. 
* Die Files sind benannt gemäß des [Namenschemas](https://github.com/cdeck3r/IoTNumb3rs/blob/master/Diagramme/README.md)
* Die Files liegen auf Github unter https://github.com/cdeck3r/IoTNumb3rs/tree/master/Diagramme 

#### Sprintdauer

Start: 19.12.2018  
Ende: 08.01.2019

#### Fortschrittsverfolgung

Datenerfassung: [stats.csv](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/stats.csv)  
Datenqualität: [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md)

### Vorgehen

### Hinweise zur Anfertigung von Diagrammen

* Ein Tabellenblatt (Reiter in Excel) enthält nur ein Diagramm.
* Ein Tabellenblatt beginnt immer mit einer Überschrift, die beschreibt, welches Diagramm zu sehen ist. Die Beschreibung aus dem Sprint kann verwendet werden.
* Der Reiter in Excel hat auch einen passenden Namen. Generische Namen wie "Tabelle 1" sind nicht zulässig-
* Alle Diagramme sind ordentlich zu beschriften, d.h. alle Achsenbezeichnung müssen vorhanden sein


#### Leistungsstatistiken

Im Sprint ["Datenqualitätsoffensive"](sprint-datenqualitaetsoffensive.md) wurden bereits Leistungsstatistiken erstellt.
Im aktuellen Sprint soll die Daten fortgeschrieben werden.

Jeder Nutzer erfasst seine Projektleistung (optional: von allen Nutzern) 

* Anzahl der erfassten Infografiken über die Zeit; Datenquelle: [stats.csv](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/stats.csv)
* Qualitätsindikator über die Zeit; Datenquelle: [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md), [#random channel Slack](https://iotnumb3rs.slack.com/)

#### Boxplot-Diagramme

Im Sprint ["Datenqualitätsoffensive"](sprint-datenqualitaetsoffensive.md) wurden bereits Boxplot-Diagramme erstellen. 
Mit den neuen zur Verfügung gestellten IoTNumb3rs Daten erfahren diese Diagramme ein Update.

Datenquelle: [Datenfile aus Slack](https://iotnumb3rs.slack.com/files/UCJ01E3DZ/FEXJF7SH1/combined_19_02_2018.csv)

#### Drill-Down Boxplot-Diagramme 

Hineinbohren oder Drill-Down in Daten bedeutet, dass aggregierte Merkmale auf detaillierte Werte, aus denen sie zusammengesetzt sind,
heruntergebrochen werden. Es verhält sich wie ein „Hereinzoomen“ in die Daten. 

Beispiel: Drill-Down erlaubt es, Daten wie die verschiedenen Geräteanzahlen für Prognosejahre detaillierter bzgl. den Autoren zu unterscheiden.

Die folgenden Boxplot-Diagramme sollen erstellt werden:

Drill-Down: device_count auf authorship_class

* für jede Ausprägung des Attributs authorship_class, also Blogger, Consultant, etc., soll jeweils 1 Boxplot-Diagramm erstellt werden
* x-Achse: prognosis_year
* y-Achse: device_count

Drill-Down: market_volume auf authorship_class

* für jede Ausprägung des Attributs authorship_class, also Blogger, Consultant, etc., soll jeweils 1 Boxplot-Diagramm erstellt werden
* x-Achse: prognosis_year
* y-Achse: market_volume

Drill-Down: device_count auf device_class

* Fassen Sie die Ausprägungen des Attributs device_class auf höchsten 5 verschiedene Ausprägungen zusammen
* Für jede der neuen Ausprägungen, soll jeweils 1 Boxplot-Diagramm erstellt werden
* x-Achse: prognosis_year
* y-Achse: device_count

Drill-Down: market_volume auf market_class

* Fassen Sie die Ausprägungen des Attributs market_class auf höchsten 5 verschiedene Ausprägungen zusammen
* Für jede der neuen Ausprägungen, soll jeweils 1 Boxplot-Diagramm erstellt werden
* x-Achse: prognosis_year
* y-Achse: market_volume

#### Prognoseerfüllung und Prognosehorizont

Jeder Teilnehmer soll 2 neue Diagramme erstellen, die die Prognoseerfüllung für das Attribut device_count 
und die Entwicklung der Prognose des Attributs device_count in Abhängigkeit von Prognosehorizont darstellen.

**Prognoseerfüllung:** Differenz zwischen realer device_count und prognostiziertem device_count

Dabei sind

* realer device_count: device_count für prognosis_year, wenn prognosis_year < publication_year
* prognostizierter device_count: device_count für prognosis_year, wenn prognosis_year > publication_year
* Prognoseerfüllung: Differenz, sie kann für den selben Wert von prognosis_year brechnet werden 

* Berechnen Sie Werte der Prognoseerfüllung für verschiedene Werte des Attributs prognosis_year
* Erstellen Sie ein Boxplot-Diagramm
* x-Achse: prognosis_year
* y-Achse: Abweichung device_count

**Prognosehorizont:** Zeitspanne zwischen prognosis_year und publication_year

* Fassen Sie die Werte des Attributes device_count verschiedener Prognosehorizonte zusammen
* Erstellen Sie ein Boxplot-Diagramm
* x-Achse: Prognosehorizont
* y-Achse: device_count

## Evaluation

Am Ende des Sprints werden die erfassten Daten analysiert und mit dem Stand vom Startdatum verglichen. Dabei werden die geforderten Resultat wie folgt gemessen

Messgröße `Total data rows`: Alle Datensätze eines Nutzers  
Messgröße `Distinct infographics`: verschiedene Infografiken eines Users  
Messgröße `Datenqualität Q`: Qualitätsindikator aus [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md)

### Stand 19.12.2018

| User | Total data rows | Distinct infographics | Datenqualität Q |
| :--- | :---: | :---: | :---: |
| JinlinHolic | 356 | 115 | 1.0 |
| MariaMarg | 311 | 98 | 1.0 |
| marielledemuth | 326 | 115 | 1.0 |
| Pattoho | 529 | 108 | 1.0 |
| **Summe** | **1522** | **436** |  |

### Stand nach Sprintende am 09.01.2018

| User | Total data rows | Distinct infographics | Datenqualität Q |
| :--- | :---: | :---: | :---: |
| JinlinHolic |  |  |  |
| MariaMarg |  |  |  |
| marielledemuth |  |  |  |
| Pattoho |  |   |  |
| **Summe** | **n/a** | **n/a** |  |

### Erfüllung der zu Beginn aufgestellten messbaren Resultate

| User | zusätzliche verschiedene \(=distinct\) infographics | Delta Q |
| :--- | :--- | :--- |
| JinlinHolic |  |  |
| MariaMarg |  |  |
| marielledemuth |  |  |
| Pattoho |  |  |


