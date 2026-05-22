# k.ps1
# Short launcher for start_kimi.ps1. Keep this file ASCII-only.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1"
iex (iwr -UseBasicParsing $url).Content
