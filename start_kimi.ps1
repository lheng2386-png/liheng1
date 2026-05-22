# start_kimi.ps1
# ASCII-only Windows PowerShell 5.1 script for school Windows 10 terminals.
# Do NOT put your API key in this file or commit it to GitHub.

$script:KimiApiKey = $null
$script:ClipboardReady = $false
$script:TlsReady = $false

try {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $script:TlsReady = $true
} catch {
    try {
        [Net.ServicePointManager]::SecurityProtocol = 3072
        $script:TlsReady = $true
    } catch {
        $script:TlsReady = $false
    }
}

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $script:ClipboardReady = $true
} catch {
    $script:ClipboardReady = $false
}

function Protect-SecretText {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    $safeText = $Text
    if (-not [string]::IsNullOrWhiteSpace($script:KimiApiKey)) {
        $safeText = $safeText.Replace($script:KimiApiKey, "[API_KEY_HIDDEN]")
    }

    return $safeText
}

function Write-SafeOutput {
    param(
        [string]$Text
    )

    Write-Output (Protect-SecretText -Text $Text)
}

function Test-DirectoryWritable {
    param(
        [string]$Directory
    )

    try {
        if ([string]::IsNullOrWhiteSpace($Directory)) {
            return $false
        }

        if (-not (Test-Path $Directory)) {
            return $false
        }

        $testFile = Join-Path $Directory ("kimi_write_test_" + [Guid]::NewGuid().ToString("N") + ".tmp")
        [System.IO.File]::WriteAllText($testFile, "test", [System.Text.Encoding]::ASCII)
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Get-AnswerFilePath {
    $currentDir = (Get-Location).Path

    if (Test-DirectoryWritable -Directory $currentDir) {
        return (Join-Path $currentDir "last_answer.txt")
    }

    $tempDir = $env:TEMP
    if ([string]::IsNullOrWhiteSpace($tempDir)) {
        $tempDir = [System.IO.Path]::GetTempPath()
    }

    return (Join-Path $tempDir "last_answer.txt")
}

function Show-Preflight {
    param(
        [string]$AnswerFilePath
    )

    Write-Output "Preflight:"
    Write-Output ("  PowerShell: " + $PSVersionTable.PSVersion.ToString())
    if ($PSVersionTable.PSVersion.Major -gt 5) {
        Write-Output "  Note: This script is designed for Windows PowerShell 5.1, but should still run here."
    }

    if ($script:TlsReady) {
        Write-Output "  TLS 1.2: OK"
    } else {
        Write-Output "  TLS 1.2: failed to set"
    }

    if ($script:ClipboardReady) {
        Write-Output "  Clipboard assemblies: OK"
    } else {
        Write-Output "  Clipboard assemblies: unavailable. /clip may still try Get-Clipboard; /shot may not work."
    }

    Write-Output ("  Current directory: " + (Get-Location).Path)
    Write-Output ("  Answer file: " + $AnswerFilePath)
    if ((Split-Path -Parent $AnswerFilePath) -ne (Get-Location).Path) {
        Write-Output "  Current directory is not writable. Answers will be saved in TEMP."
    } else {
        Write-Output "  Answer file write test: OK"
    }
    Write-Output ""
}

function Read-KimiApiKey {
    if (-not [string]::IsNullOrWhiteSpace($script:KimiApiKey)) {
        return
    }

    Write-Output "Kimi terminal chat starter"
    Write-Output "Do NOT put your API key into GitHub."
    Write-Output "Paste your Kimi API Key when asked. It will not be shown on screen."
    Write-Output ""

    try {
        $secureKey = Read-Host "Enter Kimi API Key" -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
        try {
            $script:KimiApiKey = ([Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)).Trim()
        } finally {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    } catch {
        Write-Output "ERROR: Failed to read API key."
        exit 1
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
    Write-Output "  /model     Show model, mode, thinking status, context size, and answer file."
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

    [void]$Messages.Add(@{
        role = "system"
        content = (New-SystemPrompt -AnswerMode $AnswerMode -SpeedMode $SpeedMode)
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

        # Keep the system prompt at index 0. Remove old non-system messages in place.
        $Messages.RemoveAt(1)
    }
}

function Remove-LastUserMessage {
    param(
        [System.Collections.ArrayList]$Messages
    )

    try {
        if ($Messages.Count -gt 1) {
            $lastIndex = $Messages.Count - 1
            if ($Messages[$lastIndex].role -eq "user") {
                $Messages.RemoveAt($lastIndex)
            }
        }
    } catch {
        Write-Output "Context cleanup skipped."
    }
}

function Get-ClipboardTextSafe {
    try {
        if ($script:ClipboardReady -and [System.Windows.Forms.Clipboard]::ContainsText()) {
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

    if ([string]::IsNullOrEmpty($Text)) {
        return $false
    }

    try {
        if ($script:ClipboardReady) {
            [System.Windows.Forms.Clipboard]::SetText($Text)
            return $true
        }
    } catch {}

    try {
        Set-Clipboard -Value $Text -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-ClipboardImageDataUrl {
    if (-not $script:ClipboardReady) {
        return $null
    }

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
            if ($bytes.Length -gt 5242880) {
                return "IMAGE_TOO_LARGE"
            }

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
        [int]$MaxTokens,
        [bool]$IncludeThinking
    )

    try {
        $bodyObj = @{
            model = $Model
            messages = $Messages
            max_tokens = $MaxTokens
        }

        if ($IncludeThinking) {
            if ($SpeedMode -eq "fast") {
                $bodyObj.thinking = @{
                    type = "disabled"
                }
            } else {
                $bodyObj.thinking = @{
                    type = "enabled"
                }
            }
        }

        return ($bodyObj | ConvertTo-Json -Depth 30)
    } catch {
        throw "Request body build failed."
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

    $detail = Protect-SecretText -Text $detail

    return @{
        StatusCode = $statusCode
        StatusDescription = $statusDescription
        Detail = $detail
    }
}

function Write-RequestError {
    param(
        [hashtable]$ErrorInfo
    )

    if ($null -ne $ErrorInfo.StatusCode) {
        Write-Output ("HTTP status: " + $ErrorInfo.StatusCode + " " + $ErrorInfo.StatusDescription)
    }

    Write-Output "Error detail:"
    Write-SafeOutput $ErrorInfo.Detail

    if ($ErrorInfo.StatusCode -eq 401) {
        Write-Output "Tip: API key is invalid, expired, or has no permission."
    } elseif ($ErrorInfo.StatusCode -eq 429) {
        Write-Output "Tip: Rate limit, quota, or account balance issue."
    } elseif ($ErrorInfo.StatusCode -eq 400) {
        Write-Output "Tip: Request body format issue. It may be image format, content length, or thinking parameter."
    } elseif ($ErrorInfo.Detail -match "timed out|timeout|NameResolution|Unable to connect|connection|DNS|proxy") {
        Write-Output "Tip: Check campus network, proxy, GitHub Raw, and api.moonshot.cn access."
    } else {
        Write-Output "Tip: Check API key, campus network, proxy, GitHub Raw, and api.moonshot.cn."
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
        Write-Output ("Path: " + $Path)
        return $false
    }
}

function Open-LastAnswerFile {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Output "No saved answer yet."
        return
    }

    try {
        Start-Process notepad $Path -ErrorAction Stop
    } catch {
        Write-Output "Failed to open Notepad. The answer is still saved here:"
        Write-Output $Path
    }
}

function Invoke-KimiRequest {
    param(
        [string]$ApiUrl,
        [string]$ApiKey,
        [string]$Model,
        [System.Collections.ArrayList]$Messages,
        [string]$SpeedMode,
        [int]$MaxTokens,
        [bool]$IncludeThinking
    )

    $json = New-RequestBodyJson `
        -Model $Model `
        -Messages $Messages `
        -SpeedMode $SpeedMode `
        -MaxTokens $MaxTokens `
        -IncludeThinking $IncludeThinking

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
        -TimeoutSec 120 `
        -ErrorAction Stop
}

function Invoke-KimiRequestWithRetry {
    param(
        [string]$ApiUrl,
        [string]$ApiKey,
        [string]$Model,
        [System.Collections.ArrayList]$Messages,
        [string]$SpeedMode,
        [int]$MaxTokens
    )

    try {
        $response = Invoke-KimiRequest `
            -ApiUrl $ApiUrl `
            -ApiKey $ApiKey `
            -Model $Model `
            -Messages $Messages `
            -SpeedMode $SpeedMode `
            -MaxTokens $MaxTokens `
            -IncludeThinking $true

        return @{
            Success = $true
            Response = $response
            Error = $null
            Warning = $null
        }
    } catch {
        $firstError = Get-HttpErrorText -ErrorRecord $_
        $mayBeThinkingProblem = ($firstError.StatusCode -eq 400 -or $firstError.Detail -match "thinking")

        if ($mayBeThinkingProblem) {
            try {
                $response = Invoke-KimiRequest `
                    -ApiUrl $ApiUrl `
                    -ApiKey $ApiKey `
                    -Model $Model `
                    -Messages $Messages `
                    -SpeedMode $SpeedMode `
                    -MaxTokens $MaxTokens `
                    -IncludeThinking $false

                return @{
                    Success = $true
                    Response = $response
                    Error = $null
                    Warning = "Thinking parameter may not be accepted by this endpoint. Retried without it."
                }
            } catch {
                return @{
                    Success = $false
                    Response = $null
                    Error = (Get-HttpErrorText -ErrorRecord $_)
                    Warning = $null
                }
            }
        }

        return @{
            Success = $false
            Response = $null
            Error = $firstError
            Warning = $null
        }
    }
}

function kimi-chat {
    $apiUrl = "https://api.moonshot.cn/v1/chat/completions"
    $model = "kimi-k2.6"
    $speedMode = "quality"
    $answerMode = "chat"
    $maxTokens = 4000
    $maxMessages = 25
    $lastAnswerFile = Get-AnswerFilePath
    $lastAnswer = ""

    Show-Preflight -AnswerFilePath $lastAnswerFile
    Read-KimiApiKey

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
        try {
            $q = Read-Host "You"
        } catch {
            Write-Output "Input failed. Try again, or type /exit to quit."
            continue
        }

        if ($null -eq $q) {
            continue
        }

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
            Write-Output ("Model: " + $model)
            Write-Output ("Answer mode: " + $answerMode)
            Write-Output ("Thinking mode: " + $speedMode)
            Write-Output ("Context messages: " + $messages.Count)
            Write-Output ("Answer file: " + $lastAnswerFile)
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
            Open-LastAnswerFile -Path $lastAnswerFile
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
        } elseif ($cmd -eq "/shot") {
            $dataUrl = Get-ClipboardImageDataUrl

            if ($dataUrl -eq "IMAGE_TOO_LARGE") {
                Write-Output "Clipboard image is too large. Try a smaller screenshot, or copy the problem text and use /clip."
                continue
            }

            if ([string]::IsNullOrWhiteSpace($dataUrl)) {
                Write-Output "Clipboard has no image. Use Win + Shift + S first, then type /shot. If this lab blocks image clipboard access, use /clip instead."
                continue
            }

            try {
                $imgQuestion = Read-Host "Question for this screenshot"
            } catch {
                $imgQuestion = ""
            }

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
        } else {
            $q = $cmd
        }

        if (-not $addedUserMessage) {
            [void]$messages.Add(@{
                role = "user"
                content = $q
            })
        }

        Trim-Messages -Messages $messages -MaxCount $maxMessages

        $result = Invoke-KimiRequestWithRetry `
            -ApiUrl $apiUrl `
            -ApiKey $script:KimiApiKey `
            -Model $model `
            -Messages $messages `
            -SpeedMode $speedMode `
            -MaxTokens $maxTokens

        if (-not $result.Success) {
            Write-Output ""
            Write-Output "Request failed. The last user message has been removed from context."
            Remove-LastUserMessage -Messages $messages
            Write-RequestError -ErrorInfo $result.Error
            Write-Output ""
            Write-Output "Suggestions:"
            Write-Output "1. For long text problems, copy first, then type /clip."
            Write-Output "2. For screenshots, use Win + Shift + S first, then type /shot."
            Write-Output "3. If errors continue, type /reset."
            Write-Output "4. If terminal Chinese display is messy, type /open."
            Write-Output "5. Use /fast for short answers or /quality for hard problems."
            Write-Output ""
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($result.Warning)) {
            Write-Output $result.Warning
        }

        $res = $result.Response
        if (-not $res.choices -or -not $res.choices[0].message.content) {
            Write-Output "Empty response from API. The last user message has been removed from context."
            Remove-LastUserMessage -Messages $messages
            continue
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
}

try {
    kimi-chat
} catch {
    Write-Output ""
    Write-Output "Fatal error. The script stopped safely."
    Write-SafeOutput $_.Exception.Message
    Write-Output "You can restart PowerShell and run the launch command again."
}
