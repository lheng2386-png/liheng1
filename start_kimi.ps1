# start_kimi.ps1
# ASCII-only PowerShell script to avoid encoding errors on Windows PowerShell 5.1.
# Do NOT put your API key in this file.

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

Write-Output "Kimi terminal chat starter"
Write-Output "Do NOT put your API key into GitHub."
Write-Output "Paste your Kimi API Key when asked. It will not be shown on screen."
Write-Output ""

if (-not $env:KIMI_API_KEY) {
    $secureKey = Read-Host "Enter Kimi API Key" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $env:KIMI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
}

function New-SystemPrompt {
    param(
        [string]$AnswerMode
    )

    if ($AnswerMode -eq "code") {
        return "You are a C++ exam helper for first-year university students. The user may ask in Chinese. You must output only complete C++17 code. Do not output explanations, Markdown, or code fences. Keep the code simple and suitable for beginners."
    }

    return "You are a C++ exam and LeetCode easy problem helper for first-year university students. The user may ask in Chinese. Answer in Chinese. Focus on C++ basics, simple algorithms, debugging, and LeetCode easy problems. When the user asks for code, provide complete C++17 code first. Keep the code simple and beginner-friendly."
}

function Show-Help {
    Write-Output ""
    Write-Output "Commands:"
    Write-Output "  /clip      read clipboard and send"
    Write-Output "  /code      code-only mode"
    Write-Output "  /chat      normal explanation mode"
    Write-Output "  /fast      faster mode"
    Write-Output "  /quality   quality mode"
    Write-Output "  /reset     clear context"
    Write-Output "  /open      open last answer in Notepad"
    Write-Output "  /copy      copy last answer to clipboard"
    Write-Output "  /model     show current model and mode"
    Write-Output "  /clear     clear screen"
    Write-Output "  /help      show commands"
    Write-Output "  /exit      exit"
    Write-Output ""
}

function kimi-chat {
    if (-not $env:KIMI_API_KEY) {
        Write-Output "ERROR: KIMI_API_KEY is not set."
        return
    }

    $apiUrl = "https://api.moonshot.cn/v1/chat/completions"
    $model = "kimi-k2.6"
    $speedMode = "quality"
    $answerMode = "chat"
    $maxTokens = 4000
    $lastAnswerFile = "$PWD\kimi_last_answer.txt"
    $lastAnswer = ""

    $systemPrompt = New-SystemPrompt -AnswerMode $answerMode

    $messages = New-Object System.Collections.ArrayList
    [void]$messages.Add(@{
        role = "system"
        content = $systemPrompt
    })

    Write-Output ""
    Write-Output "Kimi chat started."
    Write-Output "Short question: type directly."
    Write-Output "Long problem: copy it first, then type /clip."
    Write-Output "Recommended: use /code before asking for complete C++ code."
    Show-Help

    while ($true) {
        $q = Read-Host "You"
        $cmd = $q.Trim()

        if ([string]::IsNullOrWhiteSpace($cmd)) {
            continue
        }

        if ($cmd -eq "/exit") {
            Write-Output "Exited."
            break
        }

        if ($cmd -eq "/" -or $cmd -eq "/help") {
            Show-Help
            continue
        }

        if ($cmd -eq "/clear") {
            Clear-Host
            continue
        }

        if ($cmd -eq "/model") {
            Write-Output "Model: $model"
            Write-Output "Speed mode: $speedMode"
            Write-Output "Answer mode: $answerMode"
            continue
        }

        if ($cmd -eq "/fast") {
            $speedMode = "fast"
            Write-Output "Switched to fast mode."
            continue
        }

        if ($cmd -eq "/quality") {
            $speedMode = "quality"
            Write-Output "Switched to quality mode."
            continue
        }

        if ($cmd -eq "/code") {
            $answerMode = "code"
            $messages.Clear()
            $systemPrompt = New-SystemPrompt -AnswerMode $answerMode
            [void]$messages.Add(@{
                role = "system"
                content = $systemPrompt
            })
            Write-Output "Switched to code-only mode. Context cleared."
            continue
        }

        if ($cmd -eq "/chat") {
            $answerMode = "chat"
            $messages.Clear()
            $systemPrompt = New-SystemPrompt -AnswerMode $answerMode
            [void]$messages.Add(@{
                role = "system"
                content = $systemPrompt
            })
            Write-Output "Switched to normal chat mode. Context cleared."
            continue
        }

        if ($cmd -eq "/open") {
            if (Test-Path $lastAnswerFile) {
                Start-Process notepad $lastAnswerFile
            } else {
                Write-Output "No saved answer yet."
            }
            continue
        }

        if ($cmd -eq "/copy") {
            if ([string]::IsNullOrWhiteSpace($lastAnswer)) {
                Write-Output "No answer to copy yet."
            } else {
                try {
                    Set-Clipboard -Value $lastAnswer
                    Write-Output "Last answer copied to clipboard."
                } catch {
                    Write-Output "Failed to copy to clipboard."
                }
            }
            continue
        }

        if ($cmd -eq "/reset") {
            $messages.Clear()
            $systemPrompt = New-SystemPrompt -AnswerMode $answerMode
            [void]$messages.Add(@{
                role = "system"
                content = $systemPrompt
            })
            Write-Output "Context cleared."
            continue
        }

        if ($cmd -eq "/clip") {
            try {
                $clipText = (Get-Clipboard) -join "`n"

                if ([string]::IsNullOrWhiteSpace($clipText)) {
                    Write-Output "Clipboard is empty. Copy the problem first, then type /clip."
                    continue
                }

                $q = $clipText
                Write-Output "Clipboard content loaded. Sending to Kimi..."
            }
            catch {
                Write-Output "Failed to read clipboard. You can type a short question directly."
                continue
            }
        } else {
            $q = $cmd
        }

        [void]$messages.Add(@{
            role = "user"
            content = $q
        })

        if ($messages.Count -gt 25) {
            $newMessages = New-Object System.Collections.ArrayList
            [void]$newMessages.Add($messages[0])

            for ($i = [Math]::Max(1, $messages.Count - 24); $i -lt $messages.Count; $i++) {
                [void]$newMessages.Add($messages[$i])
            }

            $messages = $newMessages
        }

        $headers = @{
            "Authorization" = "Bearer $env:KIMI_API_KEY"
            "Content-Type"  = "application/json; charset=utf-8"
        }

        $bodyObj = @{
            model = $model
            messages = $messages
            max_tokens = $maxTokens
        }

        if ($speedMode -eq "fast") {
            $bodyObj.thinking = @{
                type = "disabled"
            }
        }

        $json = $bodyObj | ConvertTo-Json -Depth 50
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

        try {
            $res = Invoke-RestMethod `
                -Uri $apiUrl `
                -Method Post `
                -Headers $headers `
                -Body $bodyBytes

            if (-not $res.choices -or -not $res.choices[0].message.content) {
                throw "Empty response from API."
            }

            $answer = $res.choices[0].message.content
            $lastAnswer = $answer

            Write-Output ""
            Write-Output "Kimi:"
            Write-Output $answer
            Write-Output ""

            [System.IO.File]::WriteAllText($lastAnswerFile, $answer, [System.Text.Encoding]::UTF8)

            [void]$messages.Add(@{
                role = "assistant"
                content = $answer
            })
        }
        catch {
            Write-Output ""
            Write-Output "Request failed. The last question has been removed from context."

            if ($messages.Count -gt 1) {
                $messages.RemoveAt($messages.Count - 1)
            }

            $errText = ""

            if ($_.Exception.Response) {
                try {
                    $stream = $_.Exception.Response.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
                    $errText = $reader.ReadToEnd()
                } catch {
                    $errText = $_.Exception.Message
                }
            } else {
                $errText = $_.Exception.Message
            }

            if ([string]::IsNullOrWhiteSpace($errText)) {
                $errText = "No detailed error returned. Possible causes: network issue, invalid API key, rate limit, insufficient balance, or model unavailable."
            }

            Write-Output $errText
            Write-Output ""
            Write-Output "Suggestions:"
            Write-Output "1. For long problems, copy first, then type /clip."
            Write-Output "2. If errors continue, type /reset."
            Write-Output "3. If terminal display is messy, type /open."
            Write-Output "4. If it is slow, type /fast."
            Write-Output "5. If quality matters more, type /quality."
            Write-Output ""
        }
    }
}

kimi-chat
