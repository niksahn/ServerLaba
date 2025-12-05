# Portable PlantUML Setup Script
# This script downloads PlantUML JAR and creates a helper script to use it
# No administrator rights required

$ErrorActionPreference = "Stop"

$plantumlVersion = "1.2024.5"
$plantumlJar = "plantuml-$plantumlVersion.jar"
$plantumlUrl = "https://github.com/plantuml/plantuml/releases/download/v$plantumlVersion/$plantumlJar"
$plantumlDir = "$env:USERPROFILE\.plantuml"
$plantumlPath = "$plantumlDir\$plantumlJar"

Write-Host "Setting up PlantUML (portable installation)..." -ForegroundColor Green

# Create directory if it doesn't exist
if (-not (Test-Path $plantumlDir)) {
    New-Item -ItemType Directory -Path $plantumlDir -Force | Out-Null
    Write-Host "Created directory: $plantumlDir" -ForegroundColor Yellow
}

# Download PlantUML JAR if it doesn't exist
if (-not (Test-Path $plantumlPath)) {
    Write-Host "Downloading PlantUML JAR..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $plantumlUrl -OutFile $plantumlPath -UseBasicParsing
        Write-Host "Downloaded: $plantumlJar" -ForegroundColor Green
    } catch {
        Write-Host "Error downloading PlantUML: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "PlantUML JAR already exists: $plantumlPath" -ForegroundColor Green
}

# Create a helper script in the project directory
$helperScript = @"
@echo off
REM PlantUML Helper Script
REM Usage: plantuml.bat <input.puml> [output.png]

set PLANTUML_JAR=$plantumlPath
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
"@

$helperScriptPath = "plantuml.bat"
Set-Content -Path $helperScriptPath -Value $helperScript
Write-Host "Created helper script: $helperScriptPath" -ForegroundColor Green

Write-Host "`nPlantUML setup complete!" -ForegroundColor Green
Write-Host "`nUsage:" -ForegroundColor Cyan
Write-Host "  .\plantuml.bat diagrs\c4-context.puml" -ForegroundColor White
Write-Host "`nOr use directly with Java:" -ForegroundColor Cyan
Write-Host "  java -jar `"$plantumlPath`" diagrs\c4-context.puml" -ForegroundColor White
Write-Host "`nPlantUML JAR location: $plantumlPath" -ForegroundColor Gray







