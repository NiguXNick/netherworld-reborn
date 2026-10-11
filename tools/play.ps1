<#
.SYNOPSIS
  Sobe o server local e abre o DISGAEA RPG pela Steam apontando pra ele.
  Uso:  .\tools\play.ps1
#>
param(
    [string]$GameDir = "C:\Program Files (x86)\Steam\steamapps\common\DISGAEA RPG",
    [int]$Port = 8765,
    [int]$SteamAppId = 1791620
)
$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path $PSScriptRoot -Parent

# 1) Redireciona o jogo pro server local (guarda backup .original)
& "$PSScriptRoot\setup-game.ps1" -GameDir $GameDir -Port $Port

# 2) Sobe o server numa janela separada
Write-Host "Subindo o server em http://127.0.0.1:$Port ..."
Start-Process dotnet -ArgumentList "run" -WorkingDirectory $ProjectDir

# 3) Abre o jogo pela Steam
Write-Host "Abrindo DISGAEA RPG pela Steam (appid $SteamAppId) ..."
Start-Process "steam://rungameid/$SteamAppId"
