# start_kimi.ps1
# Kimi terminal chat for Windows PowerShell
# Do NOT put your API key in this file.

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Output "Kimi terminal chat starter"
Write-Output "Paste your Kimi API Key when asked. It will not be shown on screen."
Write-Output ""

$secureKey = Read-Host "Enter Kimi API Key" -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
$env:KIMI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

function kimi-chat {
    if (-not $env:KIMI_API_KEY) {
        Write-Output "ERROR: KIMI_API_KEY is not set."
        return
    }

    $model = "kimi-k2.6"
    $mode = "quality"
    $maxTokens = 4000
    $lastAnswerFile = "$PWD\kimi_last_answer.txt"

    $systemPrompt = "你是大一C++期末考试和LeetCode简单题助手。用户会用中文问问题。你要用中文回答，重点帮助用户理解C++基础题、算法题、代码错误。用户要代码时，优先给完整C++17代码，代码要简单，适合大一学生。不要使用复杂模板。用户要求只给代码时，只输出代码，不要解释。"

    $messages = New-Object System.Collections.ArrayList
    [void]$messages.Add(@{
        role = "system"
        content = $systemPrompt
    })

    Write-Output ""
    Write-Output "Kimi chat started."
    Write-Output "Short question: type directly."
    Write-Output "Long problem: copy it first, then type /clip."
    Write-Output ""
    Write-Output "Commands:"
    Write-Output "  /clip     read clipboard and send"
    Write-Output "  /reset    clear context"
    Write-Output "  /open     open last answer in Notepad"
    Write-Output "  /fast     faster mode"
    Write-Output "  /quality  quality mode"
    Write-Output "  /model    show current model"
    Write-Output "  /help     show commands"
    Write-Output "  /exit     exit"
    Write-Output ""

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
            Write-Output "Commands:"
            Write-Output "  /clip     read clipboard and send"
            Write-Output "  /reset    clear context"
            Write-Output "  /open     open last answer in Notepad"
            Write-Output "  /fast     faster mode"
            Write-Output "  /quality  quality mode"
            Write-Output "  /model    show current model"
            Write-Output "  /exit     exit"
            continue
        }

        if ($cmd -eq "/model") {
            Write-Output "Model: $model"
            Write-Output "Mode: $mode"
            continue
        }

        if ($cmd -eq "/fast") {
            $mode = "fast"
            Write-Output "Switched to fast mode."
            continue
        }

        if ($cmd -eq "/quality") {
            $mode = "quality"
            Write-Output "Switched to quality mode."
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

        if ($cmd -eq "/reset") {
            $messages.Clear()
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
                Write-Output "Failed to read clipboard."
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

        if ($mode -eq "fast") {
            $bodyObj.thinking = @{
                type = "disabled"
            }
        }

        $json = $bodyObj | ConvertTo-Json -Depth 50
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

        try {
            $res = Invoke-RestMethod `
                -Uri "https://api.moonshot.cn/v1/chat/completions" `
                -Method Post `
                -Headers $headers `
                -Body $bodyBytes

            $answer = $res.choices[0].message.content

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

            if ($_.Exception.Response) {
                try {
                    $stream = $_.Exception.Response.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
                    $errText = $reader.ReadToEnd()

                    if ([string]::IsNullOrWhiteSpace($errText)) {
                        Write-Output $_.Exception.Message
                    } else {
                        Write-Output $errText
                    }
                } catch {
                    Write-Output $_.Exception.Message
                }
            } else {
                Write-Output $_.Exception.Message
            }

            Write-Output ""
            Write-Output "Suggestions:"
            Write-Output "1. For long problems, copy first, then type /clip."
            Write-Output "2. If errors continue, type /reset."
            Write-Output "3. If terminal display is messy, type /open."
            Write-Output ""
        }
    }
}

kimi-chat
