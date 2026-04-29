param(
    [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$PollSeconds = 2
)

$allTokensPath = Join-Path $WorkspaceRoot "data\input\ALL TOKENS STATUS.xlsx"
$completedTokensPath = Join-Path $WorkspaceRoot "data\input\ALL COMPLETED TOKENS.xlsx"
$exporterPath = Join-Path $WorkspaceRoot "scripts\export_dashboard_json.py"

function Get-FileStamp {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-Item $Path).LastWriteTimeUtc.Ticks
    }
    return -1
}

function Run-Export {
    param([string]$Root, [string]$Exporter)

    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Regenerating dashboard JSON..." -ForegroundColor Cyan
    Push-Location $Root
    try {
        & python $Exporter
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Export complete." -ForegroundColor Green
        }
        else {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Export failed with exit code $LASTEXITCODE." -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path $exporterPath)) {
    Write-Host "Exporter not found: $exporterPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $allTokensPath)) {
    Write-Host "Input not found: $allTokensPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $completedTokensPath)) {
    Write-Host "Input not found: $completedTokensPath" -ForegroundColor Red
    exit 1
}

$lastAllTokensStamp = Get-FileStamp -Path $allTokensPath
$lastCompletedTokensStamp = Get-FileStamp -Path $completedTokensPath

Run-Export -Root $WorkspaceRoot -Exporter $exporterPath

Write-Host "Watching Excel files for changes..." -ForegroundColor Yellow
Write-Host "- $allTokensPath"
Write-Host "- $completedTokensPath"
Write-Host "Press Ctrl+C to stop.`n"

while ($true) {
    Start-Sleep -Seconds $PollSeconds

    $currentAllTokensStamp = Get-FileStamp -Path $allTokensPath
    $currentCompletedTokensStamp = Get-FileStamp -Path $completedTokensPath

    $allTokensChanged = $currentAllTokensStamp -ne $lastAllTokensStamp
    $completedTokensChanged = $currentCompletedTokensStamp -ne $lastCompletedTokensStamp

    if ($allTokensChanged -or $completedTokensChanged) {
        if ($allTokensChanged) {
            Write-Host "Detected change: ALL TOKENS STATUS.xlsx" -ForegroundColor Magenta
        }
        if ($completedTokensChanged) {
            Write-Host "Detected change: ALL COMPLETED TOKENS.xlsx" -ForegroundColor Magenta
        }

        Run-Export -Root $WorkspaceRoot -Exporter $exporterPath

        $lastAllTokensStamp = $currentAllTokensStamp
        $lastCompletedTokensStamp = $currentCompletedTokensStamp
    }
}
