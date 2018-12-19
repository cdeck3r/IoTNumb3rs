---
description: Mit IoTNumb3rs Daten analytisch arbeiten
---

# Sprint: Datenqualitätsoffensive 

## Ziel

Mit den IoTNumb3rs Daten analytisch arbeiten können.

## Messbare Resultate

* Jeder Nutzer erfasst 5 Tage lang, durchschnittlich 5 Infografiken pro Tag.
* Am Ende des Sprints sind insgesamt, d.h. über alle Nutzer zusammen, mindestens 100 neue Datensätze hinzugekommen.
* Am Ende des Sprints ist die [Datenqualität](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md) >95%
* Mindestens 2 Leistungsstatistiken als Balkendiagramme sind erstellt.
* Mindestens 4 Boxplot Diagramme über die IoTNumb3rs Daten sind erstellt.

Optional:
* Anzahl der duplizierter Infografiken *über* mehrere Users ist bekannt. Wie stark unterscheiden sich die von verschiedenen Usern extrahierten Daten?
* Für Boxplot Diagramme gibt es zusätzlich ein Balkendiagramm über den jeweiligen Datenumfang für jeden Boxplot.

#### Sprintdauer

Start: 10.12.2018  
Ende: 18.12.2018

#### Fortschrittsverfolgung

Datenerfassung: [stats.csv](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/stats.csv)  
Datenqualität: [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md)

### Vorgehen

#### Leistungsstatistiken

Jeder Nutzer erfasst seine Projektleistung (optional: von allen Nutzern) 

* Anzahl der erfassten Infografiken über die Zeit; Datenquelle: [stats.csv](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/stats.csv)
* Qualitätsindikator über die Zeit; Datenquelle: [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md), [#random channel Slack](https://iotnumb3rs.slack.com/)

#### Boxplot-Diagramme

Jeder Nutzer informiert sich selbständig über die Erstellung von Boxplots in Excel und stellt Diagramme zu den folgenden Merkmalen auf.

* Datenquelle: [Datenfile aus Slack](https://iotnumb3rs.slack.com/archives/CC1GNJWG2/p1543944400000100)
* Merkmal auf der x-Achse: 
    * prognosis_year
    * authorship_class
    * device_class
    * market_class
* Daten der y-Achse: 
    * device_count
    * market_volume

Es sind geeignete x/y Kombinationen zu wählen.

#### Optionale Untersuchungen

Die optionalen Fragestellungen von oben können ebenfalls auf dem [Datenfile aus Slack](https://iotnumb3rs.slack.com/archives/CC1GNJWG2/p1543944400000100) vorgenommen werden.


## Evaluation

Am Ende des Sprints werden die erfassten Daten analysiert und mit dem Stand vom Startdatum verglichen. Dabei werden die geforderten Resultat wie folgt gemessen

Messgröße `Total data rows`: Alle Datensätze eines Nutzers  
Messgröße `Distinct infographics`: verschiedene Infografiken eines Users  
Messgröße `Datenqualität Q`: Qualitätsindikator aus [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md)

### Stand 10.12.2018

| User | Total data rows | Distinct infographics | Datenqualität Q |
| :--- | :---: | :---: | :---: |
| JinlinHolic | 274 | 101 | 0.622377622378 |
| MariaMarg | 261 | 92 | 0.639405204461 |
| marielledemuth | 154 | 128 | 0.504854368932 |
| Pattoho | 517 | 106 | 0.760135135135 |
| **Summe** | **1206** | **427** |  |

### Stand nach Sprintende am 19.12.2018

| User | Total data rows | Distinct infographics | Datenqualität |
| :--- | :---: | :---: | :---: |
| JinlinHolic | 356 | 115 | 1.0 |
| MariaMarg | 311 | 98 | 1.0 |
| marielledemuth | 326 | 115 | 1.0 |
| Pattoho | 529 | 108 | 1.0 |
| **Summe** | **1522** | **436** |  |

### Erfüllung der zu Beginn aufgestellten messbaren Resultate

| User | zusätzliche verschiedene \(=distinct\) infographics | Delta Q |
| :--- | :--- | :--- |
| JinlinHolic | 14 | 0.377622378 |
| MariaMarg | 6 | 0.360594796 |
| marielledemuth | -13 | 0.495145631 |
| Pattoho | 2 | 0.239864865 |

