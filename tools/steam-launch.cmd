@echo off
REM Chamado pela Steam via Launch Options. Sobe o server local, abre o jogo
REM (passado em %*) e derruba o server quando o jogo fecha.
REM Raiz do projeto = pasta pai deste script (tools\..), sem caminho hardcoded.
for %%I in ("%~dp0..") do set "PROJ=%%~fI"

REM O .NET nao esta instalado no sistema (so o runtime, sem SDK), entao "dotnet run"
REM com o dotnet do PATH falha com "No .NET SDKs were found" e o server nunca sobe.
REM Usa o SDK portatil se existir; senao cai no dotnet do PATH.
set "DOTNET_PORTABLE=%TEMP%\drpg\dotnet"
if exist "%DOTNET_PORTABLE%\dotnet.exe" (
    set "DOTNET_ROOT=%DOTNET_PORTABLE%"
    set "PATH=%DOTNET_PORTABLE%;%PATH%"
    set "DOTNET=%DOTNET_PORTABLE%\dotnet.exe"
) else (
    set "DOTNET=dotnet"
)

REM 1) Redireciona o jogo pro server local (idempotente; guarda backup .original)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJ%\tools\setup-game.ps1"

REM 2) Sobe o server numa janela propria (log em %PROJ%\server.log), se ja nao estiver no ar
powershell -NoProfile -Command "if(Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue){exit 0}else{exit 1}"
if errorlevel 1 start "DRPG Server" /D "%PROJ%" "%DOTNET%" run

REM 2b) ESPERA o server ficar pronto na porta 8765. O boot roda o master-fix e leva ~20-30s;
REM     sem esperar, o jogo tenta o List.ini antes da hora, leva "connection refused" e desiste
REM     (= nao loga). Espera ate ~60s.
powershell -NoProfile -Command "$n=0; while(-not(Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue) -and $n -lt 120){Start-Sleep -Milliseconds 500; $n++}; if($n -ge 120){Write-Host 'AVISO: server nao respondeu em 60s'}else{Write-Host 'Server pronto na porta 8765'}"

REM 3) Abre o jogo e espera ele fechar (a Steam contabiliza o tempo jogado)
%*

REM 4) Jogo fechou -> derruba o server que esta ouvindo na porta 8765
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue | Select-Object -Expand OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }"
