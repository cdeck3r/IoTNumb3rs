@echo off

REM
REM Creates UML images
REM

REM goto into script dir
cd /D %~dp0

REM this is where the script is located
SET THIS_DIR=%~dp0
SET SCRIPT_DIR=%THIS_DIR:~0,-1%

SET PLANTUML_JAR=..\..\plantuml\plantuml.jar

java -jar %PLANTUML_JAR% numb3rspipeline_uml.txt
