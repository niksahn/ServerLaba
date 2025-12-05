@echo off
REM PlantUML Helper Script
REM Usage: plantuml.bat <input.puml> [output.png]

set PLANTUML_JAR=C:\Users\niksa\.plantuml\plantuml-1.2024.5.jar
set JAVA_CMD=java

if "%1"=="" (
    echo Usage: plantuml.bat ^<input.puml^> [output.png]
    echo Example: plantuml.bat diagrs\c4-context.puml
    exit /b 1
)

if not exist "%PLANTUML_JAR%" (
    echo Error: PlantUML JAR not found at %PLANTUML_JAR%
    echo Please run setup-plantuml.ps1 first
    exit /b 1
)

if "%2"=="" (
    %JAVA_CMD% -jar "%PLANTUML_JAR%" "%1"
) else (
    %JAVA_CMD% -jar "%PLANTUML_JAR%" -o "%2" "%1"
)
