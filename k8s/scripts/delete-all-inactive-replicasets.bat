@echo off
setlocal enabledelayedexpansion
REM Delete all inactive Replica Sets (with 0 replicas) immediately
REM Usage: delete-all-inactive-replicasets.bat

set NAMESPACE=microservices-lab

echo === Deleting all inactive Replica Sets ===
echo.

REM Get all Replica Sets with 0 replicas using PowerShell JSON parsing
echo Getting all Replica Sets with 0 replicas...
kubectl get replicasets -n %NAMESPACE% -o json > %TEMP%\all_rs.json 2>nul

if errorlevel 1 (
    echo Error retrieving Replica Sets
    exit /b 1
)

REM Extract Replica Sets with 0 replicas
powershell -Command "$rs = Get-Content '%TEMP%\all_rs.json' | ConvertFrom-Json; $rs.items | Where-Object { $_.spec.replicas -eq 0 -and $_.status.replicas -eq 0 } | ForEach-Object { $_.metadata.name }" > %TEMP%\rs_to_delete.txt 2>nul

set /a COUNT=0
set /a DELETED=0

echo Deleting inactive Replica Sets...
echo.

for /f "tokens=*" %%i in (%TEMP%\rs_to_delete.txt) do (
    if not "%%i"=="" (
        set /a COUNT+=1
        echo [!COUNT!] Deleting: %%i
        kubectl delete replicaset %%i -n %NAMESPACE% --ignore-not-found=true >nul 2>&1
        if !errorlevel! == 0 (
            set /a DELETED+=1
            echo      [OK] %%i deleted
        ) else (
            echo      [ERROR] Failed to delete %%i
        )
    )
)

del %TEMP%\all_rs.json 2>nul
del %TEMP%\rs_to_delete.txt 2>nul

echo.
if %COUNT% == 0 (
    echo No inactive Replica Sets found
) else (
    echo === Done ===
    echo Deleted: %DELETED% out of %COUNT% Replica Set(s)
)
endlocal

