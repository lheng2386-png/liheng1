# k.ps1
# Short launcher for start_kimi.ps1. Keep this file ASCII-only.
# School lab note: use jsDelivr first because GitHub Raw DNS may fail.

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    try {
        [Net.ServicePointManager]::SecurityProtocol = 3072
    } catch {}
}

$url = "https://cdn.jsdelivr.net/gh/lheng2386-png/liheng1@main/start_kimi.ps1"

try {
    $scriptText = (iwr -UseBasicParsing $url -ErrorAction Stop).Content
    if ([string]::IsNullOrWhiteSpace($scriptText)) {
        throw "Downloaded script is empty."
    }
    iex $scriptText
} catch {
    Write-Output "Failed to load start_kimi.ps1 from jsDelivr CDN."
    Write-Output "Check cdn.jsdelivr.net access, proxy settings, TLS, and the campus network."
    Write-Output "URL: $url"
    Write-Output $_.Exception.Message
}
