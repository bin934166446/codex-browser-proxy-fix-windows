[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$runtimeRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\runtimes\cua_node'

if (-not (Test-Path $runtimeRoot)) {
    throw "Runtime root not found: $runtimeRoot"
}

$backups = @(Get-ChildItem -Path $runtimeRoot -Filter 'cua-repl.mjs.bak-*' -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending)

if (-not $backups) {
    throw 'No cua-repl.mjs.bak-* backup was found.'
}

$backup = $backups[0]
$target = $backup.FullName -replace '\.bak-\d{8}-\d{6}$',''

if (-not (Test-Path $target)) {
    throw "Target runtime file not found: $target"
}

Copy-Item -LiteralPath $backup.FullName -Destination $target -Force
Write-Host "Restored: $target"
Write-Host "From    : $($backup.FullName)"
Write-Host 'Fully exit and restart Codex.'
