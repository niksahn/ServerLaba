# Fixing Chocolatey PlantUML Installation Issues

## Problem
Chocolatey installation is failing due to:
1. Missing administrator rights
2. Stale lock file: `C:\ProgramData\chocolatey\lib\689c878d6fbac0136c56be0661f715aee99b4d9c`
3. Access denied errors

## Solution Options

### Option 1: Run as Administrator (Recommended for Chocolatey)
1. Close your current command prompt
2. Right-click on **Command Prompt** or **PowerShell**
3. Select **"Run as Administrator"**
4. Run: `choco install plantuml -y`

### Option 2: Remove Stale Lock File (If Option 1 doesn't work)
1. Run Command Prompt or PowerShell **as Administrator**
2. Delete the lock file:
   ```cmd
   rmdir /s /q "C:\ProgramData\chocolatey\lib\689c878d6fbac0136c56be0661f715aee99b4d9c"
   ```
3. Try installing again:
   ```cmd
   choco install plantuml -y
   ```

### Option 3: Use Portable PlantUML (No Admin Rights Required)
Use the provided `setup-plantuml.ps1` script:
```powershell
.\setup-plantuml.ps1
```

This downloads PlantUML JAR to your user directory and creates a helper script.

## Verify Installation
After installation, test with:
```cmd
plantuml -version
```

Or if using the portable version:
```cmd
.\plantuml.bat diagrs\c4-context.puml
```







