# Kimi Terminal Starter

Windows 10 school computer lab PowerShell helper for Kimi API C++ and algorithm practice.

## Start

Run these commands in the current Windows PowerShell window:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iwr -UseBasicParsing "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1" -OutFile k.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\k.ps1
```

One-line version:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -UseBasicParsing "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1" -OutFile k.ps1; Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\k.ps1
```

The script asks for your Kimi API key at runtime. Do not put the key in GitHub.

## Common Commands

- `/clip`: copy a long problem first, then send clipboard text.
- `/shot`: press Win+Shift+S first, then send the clipboard image with a question.
- `/code`: code-only mode for complete C++17 online judge submissions.
- `/chat`: normal Chinese explanation mode.
- `/fast`: concise mode, disables thinking when supported.
- `/quality`: detailed mode, enables thinking when supported.
- `/open`: open `last_answer.txt` in Notepad if terminal Chinese display is messy.
- `/copy`: copy the last answer.
- `/reset`: clear context but keep the API key in the current PowerShell process.

## Troubleshooting

- If download fails, check GitHub Raw access and the campus network.
- If requests fail, check `api.moonshot.cn`, proxy settings, balance, and API key.
- If HTTP 401 appears, re-run the script and enter a valid API key.
- If `/shot` cannot read an image, use Win+Shift+S again or use `/clip` for copied text.
