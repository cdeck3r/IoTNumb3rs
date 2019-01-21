---
description: Letztes Update der IoTNumb3rs Daten
---

# Sprint: Finales Update der IoTNumb3rs Daten

## Ziel

Datenbasis über IoT Prognosedaten fertigstellen.

## Messbare Resultate

* Jeder Nutzer erfasst 25 neue Infografiken.
* Am Ende des Sprints sind insgesamt, d.h. über alle Nutzer zusammen, mindestens 100 neue Datensätze hinzugekommen.
* Am Ende des Sprints ist die [Datenqualität](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md) **100%**
* Alle Leistungsstatistiken aus Sprint [Datenqualitätsoffensive](sprint-datenqualitaetsoffensive.md) sind mit neuen Daten fortgeschrieben.
* Alle Boxplotdiagramme der vergangenen Sprints erhalten ein Update mit neuen IoTNumb3rs Daten.
    * Descriptive Diagramme aus Sprint [Datenqualitätsoffensive](sprint-datenqualitaetsoffensive.md)  
    * Drill-Down Diagramme aus Sprint [Dateneinblicke](sprint-dateneinblicke.md) 
    * Diagramme der Prognoseerfüllung und des Prognosehorizont aus Sprint [Dateneinblicke](sprint-dateneinblicke.md) 
* Für jeden Nutzer gibt es am Sprintende 1 Excelfile und 1 PDF File, in dem alle Diagramme enthalten sind. 
* Das Excelfile ist benannt gemäß des [Namenschemas](https://github.com/cdeck3r/IoTNumb3rs/blob/master/Diagramme/README.md)
* Das Excelfile liegt auf Github unter https://github.com/cdeck3r/IoTNumb3rs/tree/master/Diagramme 

#### Sprintdauer

Start: 09.01.2019  
Ende: 15.01.2019

#### Fortschrittsverfolgung

Datenerfassung: [stats.csv](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/stats.csv)  
Datenqualität: [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md)

### Vorgehen

siehe Sprint [Datenqualitätsoffensive](sprint-datenqualitaetsoffensive.md) und Sprint [Dateneinblicke](sprint-dateneinblicke.md) 

Datenquelle: [Datenfile aus Slack](https://iotnumb3rs.slack.com/files/UCJ01E3DZ/FF9JFDTB6/combined_09012019.csv)

**Besondere Hinweise**

Der Sprint [Dateneinblicke](sprint-dateneinblicke.md) zeigte in mehreren Diagrammen Außreißer, also Datenpunkte, die mehrere Standardabweichungen vom Mittelwert entfernt sind. Das führte dazu, dass Boxplots stark gestaucht wurden und für eine Betrachtung nicht mehr sichtbar waren. Hier ist eine Filterung vorzunehmen, d.h. die Ausreißerwerte sollen nicht in den Auswertungen berücksichtigt werden. Für die Filterung sollte schrittweise und für das Diagramm spezifisch vorgegangen werden, d.h nach der Entfernung der größten Ausreißer, sollte geprüft werden, ob die Lesbarkeit und des Diagramms sind hinreichend verbessert hat. Falls nicht, wird der Vorgang wiederholt. 

Bitte die Hinweise zur Anfertigung von Diagrammen beachten.

## Evaluation

Am Ende des Sprints werden die erfassten Daten analysiert und mit dem Stand vom Startdatum verglichen. Dabei werden die geforderten Resultat wie folgt gemessen

Messgröße `Total data rows`: Alle Datensätze eines Nutzers  
Messgröße `Distinct infographics`: verschiedene Infografiken eines Users  
Messgröße `Datenqualität Q`: Qualitätsindikator aus [dq.md](https://github.com/cdeck3r/IoTNumb3rs/blob/iotdata/dq.md)

### Stand 09.01.2019

| User | Total data rows | Distinct infographics | Datenqualität Q |
| :--- | :---: | :---: | :---: |
| JinlinHolic | 418 | 139 | 1.0 |
| MariaMarg | 357 | 122 | 1.0 |
| marielledemuth | 431 | 142 | 1.0 |
| Pattoho | 617 | 133  | 0.995137763371 |
| **Summe** | **1823** | **536** |  |

### Stand nach Sprintende am 16.01.2019

| User | Total data rows | Distinct infographics | Datenqualität Q |
| :--- | :---: | :---: | :---: |
| JinlinHolic | 491 | 165 | 1.0 |
| MariaMarg | 394 | 141 | 1.0 |
| marielledemuth | 503 | 167 | 1.0 |
| Pattoho | 685 | 154 |  0.997080291971 |
| **Summe** | **2073** | **627** |  |

### Erfüllung der zu Beginn aufgestellten messbaren Resultate

| User | zusätzliche verschiedene \(=distinct\) infographics |
| :--- | :--- | 
| JinlinHolic | 26 | 
| MariaMarg | 19 |
| marielledemuth | 25 | 
| Pattoho | 21 | 
