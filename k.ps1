# k.ps1
# Short launcher for start_kimi.ps1. Keep this file ASCII-only.

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    try {
        [Net.ServicePointManager]::SecurityProtocol = 3072
    } catch {}
}

$url = "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1"

try {
    $scriptText = (iwr -UseBasicParsing $url -ErrorAction Stop).Content
    if ([string]::IsNullOrWhiteSpace($scriptText)) {
        throw "Downloaded script is empty."
    }
    iex $scriptText
} catch {
    Write-Output "Failed to load start_kimi.ps1 from GitHub Raw."
    Write-Output "Check GitHub Raw access, proxy settings, TLS, and the campus network."
    Write-Output "URL: $url"
    Write-Output $_.Exception.Message
}
