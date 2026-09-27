[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https?://')]
    [string]$ProxyUrl,

    [string]$TestUrl = 'https://chatgpt.com/backend-api/me',

    [int]$TimeoutSeconds = 12
)

$ErrorActionPreference = 'Stop'

function Invoke-CurlProbe {
    param(
        [string[]]$Arguments,
        [string]$Name
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & curl.exe @Arguments 2>&1
    $exit = $LASTEXITCODE
    $sw.Stop()

    [pscustomobject]@{
        Name       = $Name
        ExitCode   = $exit
        ElapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
        Output     = ($output -join [Environment]::NewLine)
    }
}

Write-Host '=== Codex Browser Proxy Diagnostic ==='
Write-Host "Test URL : $TestUrl"
Write-Host "Proxy URL: $ProxyUrl"
Write-Host ''

$direct = Invoke-CurlProbe -Name 'DIRECT' -Arguments @(
    '--noproxy','*',
    '--connect-timeout',[string][Math]::Min(8,$TimeoutSeconds),
    '--max-time',[string]$TimeoutSeconds,
    '-sS','-o','NUL','-D','-',
    $TestUrl
)

$proxied = Invoke-CurlProbe -Name 'PROXY' -Arguments @(
    '--proxy',$ProxyUrl,
    '--connect-timeout',[string][Math]::Min(8,$TimeoutSeconds),
    '--max-time',[string]$TimeoutSeconds,
    '-sS','-o','NUL','-D','-',
    $TestUrl
)

$direct | Format-List
$proxied | Format-List

Write-Host ''
Write-Host 'Interpretation:'
Write-Host '- A 401/403 from the proxied request still proves network reachability.'
Write-Host '- If direct fails/timeouts but proxy receives HTTP, the proxy-inheritance workaround is a strong candidate.'
Write-Host '- If both paths work, do not assume this repository matches your root cause.'
