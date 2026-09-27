[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https?://')]
    [string]$ProxyUrl,

    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$markerBegin = '// BEGIN codex-browser-proxy-fix'
$markerEnd   = '// END codex-browser-proxy-fix'

function Get-CurrentPluginManifest {
    $root = Join-Path $env:USERPROFILE '.codex\plugins\cache\openai-bundled\unified-computer-use'
    if (-not (Test-Path $root)) { return $null }

    Get-ChildItem -Path $root -Filter '.mcp.json' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-StringLeaves {
    param([object]$Value)
    if ($null -eq $Value) { return }
    if ($Value -is [string]) { $Value; return }
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($k in $Value.Keys) { Get-StringLeaves $Value[$k] }
        return
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        foreach ($v in $Value) { Get-StringLeaves $v }
        return
    }
    $props = $Value.PSObject.Properties
    if ($props) {
        foreach ($p in $props) { Get-StringLeaves $p.Value }
    }
}

function Get-CurrentCuaRepl {
    param([System.IO.FileInfo]$Manifest)

    $runtimeRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\runtimes\cua_node'
    if (-not (Test-Path $runtimeRoot)) { return $null }

    $preferredRuntimeId = $null
    if ($Manifest) {
        try {
            $obj = Get-Content -Raw -LiteralPath $Manifest.FullName | ConvertFrom-Json
            $strings = @(Get-StringLeaves $obj)
            foreach ($s in $strings) {
                if ($s -match 'cua_node[\\/](?<id>[^\\/]+)') {
                    $preferredRuntimeId = $Matches.id
                    break
                }
            }
        } catch {
            Write-Warning "Could not parse manifest JSON: $($_.Exception.Message)"
        }
    }

    $all = @(Get-ChildItem -Path $runtimeRoot -Filter 'cua-repl.mjs' -File -Recurse -ErrorAction SilentlyContinue)
    if (-not $all) { return $null }

    if ($preferredRuntimeId) {
        $preferred = $all | Where-Object { $_.FullName -match [regex]::Escape("cua_node\$preferredRuntimeId\") } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($preferred) { return $preferred }
    }

    $all | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

function Get-NodeExeForRuntime {
    param([System.IO.FileInfo]$CuaRepl)
    $p = $CuaRepl.Directory
    while ($p) {
        $candidate = Join-Path $p.FullName 'node.exe'
        if (Test-Path $candidate) { return $candidate }
        $candidate2 = Join-Path $p.FullName 'bin\node.exe'
        if (Test-Path $candidate2) { return $candidate2 }
        $p = $p.Parent
    }
    return $null
}

$manifest = Get-CurrentPluginManifest
$cua = Get-CurrentCuaRepl -Manifest $manifest

Write-Host '=== Codex Browser Proxy Fix ==='
Write-Host "Manifest : $($manifest.FullName)"
Write-Host "CUA REPL  : $($cua.FullName)"
Write-Host "Proxy URL : $ProxyUrl"

if (-not $cua) {
    throw 'Could not find the active/latest cua-repl.mjs. Stop here; do not guess a path.'
}

$content = Get-Content -Raw -LiteralPath $cua.FullName
if ($content.Contains($markerBegin)) {
    Write-Host 'Patch marker already present. No duplicate patch will be added.'
    exit 0
}

if ($content -notmatch 'await\s+cua_repl\.launch\s*\(\s*\)\s*;') {
    throw 'Expected "await cua_repl.launch();" was not found. Runtime layout changed; refusing to patch automatically.'
}

$escaped = $ProxyUrl.Replace('\\','\\\\').Replace('"','\\"')
$block = @"
$markerBegin
Object.assign(process.env, {
  NODE_USE_ENV_PROXY: "1",
  HTTP_PROXY: "$escaped",
  HTTPS_PROXY: "$escaped",
  http_proxy: "$escaped",
  https_proxy: "$escaped",
  NO_PROXY: "localhost,127.0.0.1,::1",
  no_proxy: "localhost,127.0.0.1,::1"
});
$markerEnd
"@

$newContent = [regex]::Replace(
    $content,
    '(?m)^(?<indent>\s*)(?<launch>await\s+cua_repl\.launch\s*\(\s*\)\s*;)',
    { param($m) $m.Groups['indent'].Value + ($block -replace "`n", "`n" + $m.Groups['indent'].Value) + "`r`n" + $m.Groups['indent'].Value + $m.Groups['launch'].Value },
    1
)

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Dry run only. Re-run with -Apply to modify the runtime.'
    Write-Host 'A timestamped backup will be created and syntax checked.'
    exit 0
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "$($cua.FullName).bak-$stamp"
Copy-Item -LiteralPath $cua.FullName -Destination $backup -Force
Write-Host "Backup   : $backup"

try {
    Set-Content -LiteralPath $cua.FullName -Value $newContent -Encoding UTF8 -NoNewline

    $node = Get-NodeExeForRuntime -CuaRepl $cua
    if (-not $node) {
        throw 'Could not find the runtime node.exe for syntax validation.'
    }

    Write-Host "Node     : $node"
    & $node --check $cua.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "node --check failed with exit code $LASTEXITCODE"
    }

    Write-Host ''
    Write-Host 'PATCH_APPLIED=YES'
    Write-Host 'Syntax check: PASS'
    Write-Host 'Now fully exit Codex (including tray/background process), restart it, and verify cua.getState() plus real tab/page reads.'
}
catch {
    Write-Warning "Patch failed: $($_.Exception.Message)"
    Copy-Item -LiteralPath $backup -Destination $cua.FullName -Force
    Write-Warning 'Original file restored from backup.'
    throw
}
