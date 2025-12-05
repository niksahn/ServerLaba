#!/bin/bash
# PlantUML Helper Script for Bash/Git Bash
# Usage: ./plantuml.sh <input.puml> [output.png]

PLANTUML_JAR="$HOME/.plantuml/plantuml-1.2024.5.jar"

if [ -z "$1" ]; then
    echo "Usage: ./plantuml.sh <input.puml> [output.png]"
    echo "Example: ./plantuml.sh diagrs/c4-context.puml"
    exit 1
fi

if [ ! -f "$PLANTUML_JAR" ]; then
    echo "Error: PlantUML JAR not found at $PLANTUML_JAR"
    echo "Please run: powershell -ExecutionPolicy Bypass -File setup-plantuml.ps1"
    exit 1
fi

if [ -z "$2" ]; then
    java -jar "$PLANTUML_JAR" "$1"
else
    java -jar "$PLANTUML_JAR" -o "$2" "$1"
fi







