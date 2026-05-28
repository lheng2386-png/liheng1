# Kimi Terminal Starter

This repository provides a Windows PowerShell starter for using the Kimi API on Windows 10 school lab computers.

The main script is `start_kimi.ps1`.

Project goals:

- Use Windows PowerShell 5.1 on school Windows 10 computers.
- Do not require browser login.
- Do not require a phone.
- Do not require a USB drive.
- Do not require PowerShell 7.
- Do not require Python.
- Do not require npm.
- Do not require `curl.exe`.
- Do not require third-party PowerShell modules.
- Ask for the Kimi API Key at runtime.
- Never hardcode a real API key in `README.md`, `k.ps1`, or `start_kimi.ps1`.

## Recommended For Tested School Lab Computers

Use this command first on the tested school Windows 10 lab environment:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072; irm "https://cdn.jsdelivr.net/gh/lheng2386-png/liheng1@main/k.ps1"|iex
```

Why this is the first recommended command:

- This is the recommended command for the tested school Windows 10 lab environment.
- In the real school lab test, `raw.githubusercontent.com` failed DNS resolution.
- The observed PowerShell error was: `The remote name could not be resolved: raw.githubusercontent.com`.
- `cdn.jsdelivr.net` worked successfully in the tested school network.
- This command downloads `k.ps1` through the jsDelivr CDN. The launcher then downloads `start_kimi.ps1` through jsDelivr and runs it.
- It does not save the launcher permanently. For step-by-step debugging, use the multi-line version below.

After startup, the script asks for your Kimi API Key at runtime. Do not put your API key into this repository.

## Multi-Line jsDelivr Version

Use this version when you want easier debugging, or when you want to see which step fails. It downloads `start_kimi.ps1` through jsDelivr and runs it locally as `k.ps1`:

```powershell
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
Remove-Item .\k.ps1 -ErrorAction SilentlyContinue
iwr -UseBasicParsing "https://cdn.jsdelivr.net/gh/lheng2386-png/liheng1@main/start_kimi.ps1" -OutFile .\k.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\k.ps1
```

## WebClient Fallback

Try this if `iwr` / `Invoke-WebRequest` fails in an older or stricter PowerShell environment:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072; Remove-Item .\k.ps1 -ErrorAction SilentlyContinue; $wc=New-Object Net.WebClient; $wc.Headers.Add("User-Agent","Mozilla/5.0"); $wc.DownloadFile("https://cdn.jsdelivr.net/gh/lheng2386-png/liheng1@main/start_kimi.ps1","k.ps1"); Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; .\k.ps1
```

Notes:

- This still uses the jsDelivr CDN.
- This still does not require browser login, phone, USB drive, Python, npm, `curl.exe`, or external modules.
- It uses the built-in .NET `WebClient` available in Windows PowerShell 5.1.

## Alternative: GitHub Raw Direct Access

Use GitHub Raw only if `raw.githubusercontent.com` works in your network.

If you see this error:

```text
The remote name could not be resolved: raw.githubusercontent.com
```

use the jsDelivr command above instead.

Short GitHub Raw command:

```powershell
irm "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/k.ps1" | iex
```

GitHub Raw TLS-compatible command:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072; iex (iwr -UseBasicParsing "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/k.ps1").Content
```

GitHub Raw stable download command:

```powershell
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Remove-Item .\k.ps1 -ErrorAction SilentlyContinue; iwr -UseBasicParsing "https://raw.githubusercontent.com/lheng2386-png/liheng1/main/start_kimi.ps1" -OutFile .\k.ps1; Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; .\k.ps1
```

All PowerShell commands in this README wrap URLs in double quotes. Some school lab PowerShell environments parse bare URLs unreliably.

## jsDelivr Cache Note

jsDelivr may cache GitHub files. After updating `start_kimi.ps1` on GitHub, the CDN version may not refresh instantly.

For normal school lab usage this is fine. If you are testing a just-updated script, wait a little or use GitHub Raw if it works in your network.

## Common Commands Inside The Tool

| Command | Purpose |
| --- | --- |
| `/help` | Show available commands. |
| `/clip` | Read clipboard text and send it to Kimi. Useful after copying a long problem statement. |
| `/shot` | Read a screenshot from the clipboard after `Win + Shift + S`, then ask a question about it. |
| `/code` | Switch to code-only mode for complete C++17 online judge answers. |
| `/chat` | Switch back to normal Chinese explanation mode. |
| `/fast` | Use shorter, faster answers. |
| `/quality` | Use higher-quality answers for harder problems. |
| `/reset` | Clear conversation context while keeping the API key in the current PowerShell process. |
| `/model` | Show the current model, mode, thinking status, context size, and answer file path. |
| `/open` | Open the last saved answer in Notepad. |
| `/copy` | Copy the last answer to the clipboard. |
| `/clear` | Clear the terminal screen. |
| `/exit` | Exit the tool. |

## Recommended Workflow

Normal question:

```text
Type your question directly.
```

Long problem statement:

```text
1. Copy the problem text.
2. In PowerShell, type /clip.
```

Screenshot problem:

```text
1. Press Win + Shift + S and take a screenshot.
2. In PowerShell, type /shot.
3. Enter a question, for example: Please solve this problem.
```

Online judge code-only answer:

```text
1. Type /code.
2. Copy the problem and type /clip, or type the problem directly.
3. The answer should be complete C++17 code without Markdown fences.
```

If Chinese output in the terminal looks messy:

```text
/open
```

The tool saves the last answer as `last_answer.txt` and opens it in Notepad.

## Startup Test

After running the startup command, you should see:

```text
Kimi terminal chat starter
Enter Kimi API Key
```

When you enter the API key, the text is hidden on screen. This is normal.

Then try:

```text
/help
```

You should see the command list.

Then try:

```text
/model
```

You should see model and mode information, including the answer file path.

## Troubleshooting

### Error: The remote name could not be resolved: raw.githubusercontent.com

Meaning:

The school network or DNS cannot resolve GitHub Raw.

Solution:

Use the jsDelivr CDN startup command:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072; irm "https://cdn.jsdelivr.net/gh/lheng2386-png/liheng1@main/k.ps1"|iex
```

### `iwr` or `Invoke-WebRequest` fails

Try the WebClient fallback:

```powershell
[Net.ServicePointManager]::SecurityProtocol=3072; Remove-Item .\k.ps1 -ErrorAction SilentlyContinue; $wc=New-Object Net.WebClient; $wc.Headers.Add("User-Agent","Mozilla/5.0"); $wc.DownloadFile("https://cdn.jsdelivr.net/gh/lheng2386-png/liheng1@main/start_kimi.ps1","k.ps1"); Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; .\k.ps1
```

### ExecutionPolicy blocks `.\k.ps1`

Make sure the startup command includes:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

This only affects the current PowerShell process. It does not permanently change the school computer policy.

### HTTP 401

HTTP 401 usually means the API key is invalid, expired, or has no permission.

Restart the script and enter the correct Kimi API Key.

### HTTP 429

HTTP 429 usually means rate limit, quota, account balance, or API usage limit.

Wait and try again, or check your Moonshot/Kimi API account.

### `/clip` says the clipboard is empty

Copy text first, then type:

```text
/clip
```

If you copied an image, use `/shot` instead.

### Screenshot cannot be read

Use `Win + Shift + S` first, then type:

```text
/shot
```

If the school computer blocks image clipboard access, copy the problem text and use `/clip`.

## Security Notes

- Do not put a real API key in `README.md`.
- Do not put a real API key in `k.ps1`.
- Do not put a real API key in `start_kimi.ps1`.
- The script asks for the Kimi API Key at runtime.
- The script does not save the API key to `last_answer.txt`.
- The script does not print the full Authorization header.
- Public GitHub repositories can be read by other people.
