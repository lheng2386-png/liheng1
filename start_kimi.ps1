# start_kimi.ps1
# ASCII-only Windows PowerShell 5.1 script for school Windows 10 terminals.
# Do NOT put your API key in this file or commit it to GitHub.

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {}

$script:KimiApiKey = $null

function Read-KimiApiKey {
    if (-not [string]::IsNullOrWhiteSpace($script:KimiApiKey)) {
        return
    }

    Write-Output "Kimi terminal chat starter"
    Write-Output "Do NOT put your API key into GitHub."
    Write-Output "Paste your Kimi API Key when asked. It will not be shown on screen."
    Write-Output ""

    $secureKey = Read-Host "Enter Kimi API Key" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    try {
        $script:KimiApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }

    if ([string]::IsNullOrWhiteSpace($script:KimiApiKey)) {
        Write-Output "ERROR: API key is empty. Restart the script and enter a valid key."
        exit 1
    }
}

function New-SystemPrompt {
    param(
        [string]$AnswerMode,
        [string]$SpeedMode
    )

    $base = "You are a Kimi API assistant used in a Windows 10 school computer lab for C++ and algorithm review. The user may ask in Chinese. Always answer in Chinese unless code-only mode is active. Never reveal secrets."

    if ($AnswerMode -eq "code") {
        return "$base Code-only mode is active. Output only one complete C++17 program. Do not explain. Do not use Markdown. Do not use code fences. Do not add text before or after the code. Keep the code suitable for online judges and beginner-friendly when possible."
    }

    if ($SpeedMode -eq "fast") {
        return "$base Fast mode is active. Keep answers concise. For algorithm problems, give the key idea and complete C++17 code when useful."
    }

    return "$base Normal chat mode is active. Explain ideas, key points, debugging steps, and C++17 code when useful. Be beginner-friendly and practical for exam or online judge practice."
}

function Show-Help {
    Write-Output ""
    Write-Output "Commands:"
    Write-Output "  /clip      Read clipboard text and send it."
    Write-Output "  /shot      Read clipboard image from Win+Shift+S and send it with a question."
    Write-Output "  /code      Switch to code-only mode. Answers are complete C++17 code only."
    Write-Output "  /chat      Switch back to normal Chinese explanation mode."
    Write-Output "  /fast      Fast mode. Disable thinking when the API supports it."
    Write-Output "  /quality   Quality mode. Enable thinking when the API supports it."
    Write-Output "  /reset     Clear context but keep the API key."
    Write-Output "  /open      Open last_answer.txt in Notepad."
    Write-Output "  /copy      Copy the last answer to clipboard."
    Write-Output "  /model     Show model, mode, thinking status, and context size."
    Write-Output "  /clear     Clear the screen."
    Write-Output "  /help      Show this help."
    Write-Output "  /exit      Exit."
    Write-Output ""
}

function Add-SystemMessage {
    param(
        [System.Collections.ArrayList]$Messages,
        [string]$AnswerMode,
        [string]$SpeedMode
    )

    $systemPrompt = New-SystemPrompt -AnswerMode $AnswerMode -SpeedMode $SpeedMode

    [void]$Messages.Add(@{
        role = "system"
        content = $systemPrompt
    })
}

function Reset-Messages {
    param(
        [System.Collections.ArrayList]$Messages,
        [string]$AnswerMode,
        [string]$SpeedMode
    )

    $Messages.Clear()
    Add-SystemMessage -Messages $Messages -AnswerMode $AnswerMode -SpeedMode $SpeedMode
}

function Update-SystemMessage {
    param(
        [System.Collections.ArrayList]$Messages,
        [string]$AnswerMode,
        [string]$SpeedMode
    )

    $systemPrompt = New-SystemPrompt -AnswerMode $AnswerMode -SpeedMode $SpeedMode

    if ($Messages.Count -eq 0) {
        [void]$Messages.Add(@{
            role = "system"
            content = $systemPrompt
        })
        return
    }

    $Messages[0] = @{
        role = "system"
        content = $systemPrompt
    }
}

function Trim-Messages {
    param(
        [System.Collections.ArrayList]$Messages,
        [int]$MaxCount = 25
    )

    while ($Messages.Count -gt $MaxCount) {
        if ($Messages.Count -le 2) {
            break
        }

        # Keep the system prompt at index 0. Remove the oldest non-system item.
        # Do not assign a sliced array back to $Messages; that creates a fixed-size array.
        $Messages.RemoveAt(1)
    }
}

function Remove-LastUserMessage {
    param(
        [System.Collections.ArrayList]$Messages
    )

    try {
        if ($Messages.Count -gt 1) {
            $Messages.RemoveAt($Messages.Count - 1)
        }
    } catch {
        Write-Output "Context cleanup skipped."
    }
}

function Get-ClipboardTextSafe {
    try {
        if ([System.Windows.Forms.Clipboard]::ContainsText()) {
            return [System.Windows.Forms.Clipboard]::GetText()
        }
    } catch {}

    try {
        $value = Get-Clipboard -ErrorAction Stop
        if ($null -eq $value) {
            return $null
        }
        return ($value -join "`n")
    } catch {
        return $null
    }
}

function Set-ClipboardTextSafe {
    param(
        [string]$Text
    )

    try {
        [System.Windows.Forms.Clipboard]::SetText($Text)
        return $true
    } catch {}

    try {
        Set-Clipboard -Value $Text -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-ClipboardImageDataUrl {
    try {
        if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
            return $null
        }

        $img = [System.Windows.Forms.Clipboard]::GetImage()
        if ($null -eq $img) {
            return $null
        }

        $ms = New-Object System.IO.MemoryStream
        try {
            $img.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $bytes = $ms.ToArray()
            $base64 = [Convert]::ToBase64String($bytes)
            return "data:image/png;base64,$base64"
        } finally {
            $ms.Dispose()
            $img.Dispose()
        }
    } catch {
        return $null
    }
}

function New-RequestBodyJson {
    param(
        [string]$Model,
        [System.Collections.ArrayList]$Messages,
        [string]$SpeedMode,
        [int]$MaxTokens
    )

    $bodyObj = @{
        model = $Model
        messages = $Messages
        max_tokens = $MaxTokens
    }

    if ($SpeedMode -eq "fast") {
        $bodyObj.thinking = @{
            type = "disabled"
        }
    } else {
        $bodyObj.thinking = @{
            type = "enabled"
        }
    }

    try {
        return ($bodyObj | ConvertTo-Json -Depth 20)
    } catch {
        throw "Request body build failed: JSON serialization error. $($_.Exception.Message)"
    }
}

function Get-HttpErrorText {
    param(
        [object]$ErrorRecord
    )

    $statusCode = $null
    $statusDescription = $null
    $detail = $null

    try {
        if ($ErrorRecord.Exception.Response) {
            $statusCode = [int]$ErrorRecord.Exception.Response.StatusCode
            $statusDescription = $ErrorRecord.Exception.Response.StatusDescription

            try {
                $stream = $ErrorRecord.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
                $detail = $reader.ReadToEnd()
                $reader.Dispose()
            } catch {
                $detail = $ErrorRecord.Exception.Message
            }
        } else {
            $detail = $ErrorRecord.Exception.Message
        }
    } catch {
        $detail = $ErrorRecord.Exception.Message
    }

    if ([string]::IsNullOrWhiteSpace($detail)) {
        $detail = "No detailed error returned."
    }

    return @{
        StatusCode = $statusCode
        StatusDescription = $statusDescription
        Detail = $detail
    }
}

function Save-LastAnswer {
    param(
        [string]$Path,
        [string]$Answer
    )

    try {
        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($Path, $Answer, $utf8Bom)
        return $true
    } catch {
        Write-Output "Failed to save last_answer.txt."
        return $false
    }
}

function Invoke-KimiRequest {
    param(
        [string]$ApiUrl,
        [string]$ApiKey,
        [string]$Model,
        [System.Collections.ArrayList]$Messages,
        [string]$SpeedMode,
        [int]$MaxTokens
    )

    $json = New-RequestBodyJson -Model $Model -Messages $Messages -SpeedMode $SpeedMode -MaxTokens $MaxTokens
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

    $headers = @{
        Authorization = "Bearer $ApiKey"
    }

    return Invoke-RestMethod `
        -Uri $ApiUrl `
        -Method Post `
        -Headers $headers `
        -ContentType "application/json; charset=utf-8" `
        -Body $bodyBytes `
        -ErrorAction Stop
}

function kimi-chat {
    Read-KimiApiKey

    $apiUrl = "https://api.moonshot.cn/v1/chat/completions"
    $model = "kimi-k2.6"
    $speedMode = "quality"
    $answerMode = "chat"
    $maxTokens = 4000
    $maxMessages = 25
    $lastAnswerFile = Join-Path (Get-Location) "last_answer.txt"
    $lastAnswer = ""

    $messages = New-Object System.Collections.ArrayList
    Add-SystemMessage -Messages $messages -AnswerMode $answerMode -SpeedMode $speedMode

    Write-Output ""
    Write-Output "Kimi chat started."
    Write-Output "Short question: type directly."
    Write-Output "Long text problem: copy it first, then type /clip."
    Write-Output "Screenshot problem: use Win + Shift + S, then type /shot."
    Write-Output "Use /code for online judge C++17 code-only answers."
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
            Write-Output "Answer mode: $answerMode"
            Write-Output "Thinking: $speedMode"
            Write-Output "Context messages: $($messages.Count)"
            continue
        }

        if ($cmd -eq "/fast") {
            $speedMode = "fast"
            Update-SystemMessage -Messages $messages -AnswerMode $answerMode -SpeedMode $speedMode
            Write-Output "Switched to fast mode. Thinking disabled when supported."
            continue
        }

        if ($cmd -eq "/quality") {
            $speedMode = "quality"
            Update-SystemMessage -Messages $messages -AnswerMode $answerMode -SpeedMode $speedMode
            Write-Output "Switched to quality mode. Thinking enabled when supported."
            continue
        }

        if ($cmd -eq "/code") {
            $answerMode = "code"
            Update-SystemMessage -Messages $messages -AnswerMode $answerMode -SpeedMode $speedMode
            Write-Output "Switched to code-only mode."
            continue
        }

        if ($cmd -eq "/chat") {
            $answerMode = "chat"
            Update-SystemMessage -Messages $messages -AnswerMode $answerMode -SpeedMode $speedMode
            Write-Output "Switched to normal chat mode."
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
            $copyText = $lastAnswer
            if ([string]::IsNullOrWhiteSpace($copyText) -and (Test-Path $lastAnswerFile)) {
                try {
                    $copyText = [System.IO.File]::ReadAllText($lastAnswerFile, [System.Text.Encoding]::UTF8)
                } catch {}
            }

            if ([string]::IsNullOrWhiteSpace($copyText)) {
                Write-Output "No answer to copy yet."
            } elseif (Set-ClipboardTextSafe -Text $copyText) {
                Write-Output "Last answer copied to clipboard."
            } else {
                Write-Output "Failed to copy to clipboard."
            }
            continue
        }

        if ($cmd -eq "/reset") {
            Reset-Messages -Messages $messages -AnswerMode $answerMode -SpeedMode $speedMode
            Write-Output "Context cleared. API key is still kept in this PowerShell process."
            continue
        }

        $addedUserMessage = $false

        if ($cmd -eq "/clip") {
            $clipText = Get-ClipboardTextSafe

            if ([string]::IsNullOrWhiteSpace($clipText)) {
                Write-Output "Clipboard is empty. Copy the problem text first, then type /clip."
                continue
            }

            $q = $clipText
            Write-Output "Clipboard text loaded. Sending to Kimi..."
        }
        elseif ($cmd -eq "/shot") {
            $dataUrl = Get-ClipboardImageDataUrl

            if ([string]::IsNullOrWhiteSpace($dataUrl)) {
                Write-Output "Clipboard has no image. Use Win + Shift + S first, then type /shot."
                Write-Output "If this school computer blocks image clipboard access, /clip still works for copied text."
                continue
            }

            $imgQuestion = Read-Host "Question for this screenshot"

            if ([string]::IsNullOrWhiteSpace($imgQuestion)) {
                $imgQuestion = "Please solve this problem. If it is a C++ or algorithm problem, explain in Chinese and provide a beginner-friendly C++17 solution."
            }

            $userContent = @(
                @{
                    type = "text"
                    text = $imgQuestion
                },
                @{
                    type = "image_url"
                    image_url = @{
                        url = $dataUrl
                    }
                }
            )

            [void]$messages.Add(@{
                role = "user"
                content = $userContent
            })

            $addedUserMessage = $true
            Write-Output "Screenshot loaded. Sending to Kimi..."
        }
        else {
            $q = $cmd
        }

        if (-not $addedUserMessage) {
            [void]$messages.Add(@{
                role = "user"
                content = $q
            })
        }

        Trim-Messages -Messages $messages -MaxCount $maxMessages

        try {
            $res = Invoke-KimiRequest `
                -ApiUrl $apiUrl `
                -ApiKey $script:KimiApiKey `
                -Model $model `
                -Messages $messages `
                -SpeedMode $speedMode `
                -MaxTokens $maxTokens

            if (-not $res.choices -or -not $res.choices[0].message.content) {
                throw "Empty response from API."
            }

            $answer = $res.choices[0].message.content
            $lastAnswer = $answer

            Write-Output ""
            Write-Output "Kimi:"
            Write-Output $answer
            Write-Output ""

            [void](Save-LastAnswer -Path $lastAnswerFile -Answer $answer)

            [void]$messages.Add(@{
                role = "assistant"
                content = $answer
            })
        }
        catch {
            Write-Output ""
            Write-Output "Request failed. The last user message has been removed from context."
            Remove-LastUserMessage -Messages $messages

            $message = $_.Exception.Message

            if ($message -like "Request body build failed:*") {
                Write-Output $message
            } else {
                $err = Get-HttpErrorText -ErrorRecord $_

                if ($null -ne $err.StatusCode) {
                    Write-Output "HTTP status: $($err.StatusCode) $($err.StatusDescription)"
                }

                Write-Output "Error detail:"
                Write-Output $err.Detail

                if ($err.StatusCode -eq 401) {
                    Write-Output "Tip: HTTP 401 usually means the API key is invalid or expired."
                } else {
                    Write-Output "Tip: Check GitHub Raw download, api.moonshot.cn, proxy settings, and the campus network."
                }
            }

            Write-Output ""
            Write-Output "Suggestions:"
            Write-Output "1. For long text problems, copy first, then type /clip."
            Write-Output "2. For screenshots, use Win + Shift + S first, then type /shot."
            Write-Output "3. If errors continue, type /reset."
            Write-Output "4. If terminal Chinese display is messy, type /open."
            Write-Output "5. Use /fast for short answers or /quality for hard problems."
            Write-Output ""
        }
    }
}

kimi-chat
