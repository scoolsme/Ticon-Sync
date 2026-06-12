Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:ProjectRoot = Split-Path -Parent $PSCommandPath
if ([string]::IsNullOrWhiteSpace($script:ProjectRoot)) { $script:ProjectRoot = (Get-Location).Path }

$script:RunProcess = $null
$script:LogFilePath = ""
$script:CmdFilePath = ""
$script:LastLogLength = 0
$script:FolderSearchProcess = $null
$script:FolderSearchLogFilePath = ""
$script:FolderSearchCmdFilePath = ""
$script:FolderSearchLastLogLength = 0
$script:GuiLastAppendedBlank = $false
$script:GuiPlanSummaryShown = $false
$script:GuiInsidePlanSummary = $false
$script:GuiSkipDuplicatePlanSummary = $false

$themeGreen = [System.Drawing.Color]::FromArgb(61, 205, 88)
$themeGreenDark = [System.Drawing.Color]::FromArgb(30, 142, 62)
$themeGreenLight = [System.Drawing.Color]::FromArgb(232, 250, 236)
$themeHeaderGlow = [System.Drawing.Color]::FromArgb(236, 255, 241)
$themeBackground = [System.Drawing.Color]::FromArgb(248, 251, 249)
$themeCard = [System.Drawing.Color]::White
$themeText = [System.Drawing.Color]::FromArgb(17, 24, 39)
$themeMutedText = [System.Drawing.Color]::FromArgb(75, 85, 99)
$themeBorder = [System.Drawing.Color]::FromArgb(220, 224, 230)
$themeWaitingBg = [System.Drawing.Color]::FromArgb(243, 244, 246)
$themeWaitingText = [System.Drawing.Color]::FromArgb(55, 65, 81)
$themeWorkingBg = [System.Drawing.Color]::FromArgb(255, 247, 230)
$themeWorkingText = [System.Drawing.Color]::FromArgb(180, 83, 9)
$themeErrorBg = [System.Drawing.Color]::FromArgb(255, 235, 235)
$themeErrorText = [System.Drawing.Color]::FromArgb(200, 0, 0)

function Add-GreenBorder {
    param([System.Windows.Forms.Control]$Control)
    $Control.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Control.Add_Paint({
        param($sender, $eventArgs)
        $pen = New-Object System.Drawing.Pen($themeGreen, 1)
        $eventArgs.Graphics.DrawRectangle($pen, 0, 0, $sender.Width - 1, $sender.Height - 1)
        $pen.Dispose()
    })
}

function Add-WhiteGreenHover {
    param([System.Windows.Forms.Button]$Button)
    $Button.Add_MouseEnter({ $this.BackColor = $themeGreenLight })
    $Button.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::White })
    $Button.Add_MouseDown({ $this.BackColor = [System.Drawing.Color]::FromArgb(220, 247, 226) })
    $Button.Add_MouseUp({ $this.BackColor = $themeGreenLight })
}

function New-GreenButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $button.Size = New-Object System.Drawing.Size($W, $H)
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.BackColor = [System.Drawing.Color]::White
    $button.ForeColor = $themeGreenDark
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = $themeGreen
    $button.FlatAppearance.BorderSize = 1
    Add-WhiteGreenHover -Button $button
    return $button
}

function Set-Status {
    param([string]$Message, [string]$Type = "Waiting")
    $statusLabel.Text = "Status: $Message"
    if ($Type -eq "Success") { $statusLabel.ForeColor = $themeGreenDark; $statusPanel.BackColor = $themeGreenLight; return }
    if ($Type -eq "Working") { $statusLabel.ForeColor = $themeWorkingText; $statusPanel.BackColor = $themeWorkingBg; return }
    if ($Type -eq "Error") { $statusLabel.ForeColor = $themeErrorText; $statusPanel.BackColor = $themeErrorBg; return }
    $statusLabel.ForeColor = $themeWaitingText
    $statusPanel.BackColor = $themeWaitingBg
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Ticon Hierarchy Creator"
$form.Size = New-Object System.Drawing.Size(960, 820)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.BackColor = $themeBackground

$accentBar = New-Object System.Windows.Forms.Panel
$accentBar.BackColor = $themeGreen
$accentBar.Location = New-Object System.Drawing.Point(0, 0)
$accentBar.Size = New-Object System.Drawing.Size(960, 7)
$form.Controls.Add($accentBar)

$headerGlow = New-Object System.Windows.Forms.Panel
$headerGlow.BackColor = $themeHeaderGlow
$headerGlow.Location = New-Object System.Drawing.Point(0, 7)
$headerGlow.Size = New-Object System.Drawing.Size(960, 72)
$form.Controls.Add($headerGlow)

$title = New-Object System.Windows.Forms.Label
$title.Text = "TiCon Hierarchy Creator"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 19, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(30, 22)
$title.ForeColor = $themeText
$title.BackColor = $themeHeaderGlow
$form.Controls.Add($title)
$title.BringToFront()

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Create TiCon hierarchy using a selected Folder UID"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(33, 58)
$subtitle.ForeColor = $themeMutedText
$subtitle.BackColor = $themeHeaderGlow
$form.Controls.Add($subtitle)
$subtitle.BringToFront()

$stepsPanel = New-Object System.Windows.Forms.Panel
$stepsPanel.BackColor = $themeCard
$stepsPanel.Location = New-Object System.Drawing.Point(30, 82)
$stepsPanel.Size = New-Object System.Drawing.Size(880, 84)
$form.Controls.Add($stepsPanel)
Add-GreenBorder -Control $stepsPanel

$stepsTitle = New-Object System.Windows.Forms.Label
$stepsTitle.Text = "Steps"
$stepsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$stepsTitle.AutoSize = $true
$stepsTitle.Location = New-Object System.Drawing.Point(18, 9)
$stepsTitle.ForeColor = $themeText
$stepsPanel.Controls.Add($stepsTitle)

$stepsText = New-Object System.Windows.Forms.Label
$stepsText.Text = "1. Enter Folder Code and click Get UID`n2. Copy the required Folder UID from the result`n3. Paste UID in Folder UID field and click Create"
$stepsText.Font = New-Object System.Drawing.Font("Segoe UI", 8.8)
$stepsText.AutoSize = $true
$stepsText.Location = New-Object System.Drawing.Point(18, 30)
$stepsText.ForeColor = $themeMutedText
$stepsPanel.Controls.Add($stepsText)

$inputPanel = New-Object System.Windows.Forms.Panel
$inputPanel.BackColor = $themeCard
$inputPanel.Location = New-Object System.Drawing.Point(30, 176)
$inputPanel.Size = New-Object System.Drawing.Size(880, 100)
$form.Controls.Add($inputPanel)
Add-GreenBorder -Control $inputPanel

$inputTitle = New-Object System.Windows.Forms.Label
$inputTitle.Text = "Target folder selection"
$inputTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$inputTitle.AutoSize = $true
$inputTitle.Location = New-Object System.Drawing.Point(18, 8)
$inputTitle.ForeColor = $themeText
$inputPanel.Controls.Add($inputTitle)

$folderCodeLabel = New-Object System.Windows.Forms.Label
$folderCodeLabel.Text = "Folder Code:"
$folderCodeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$folderCodeLabel.AutoSize = $true
$folderCodeLabel.Location = New-Object System.Drawing.Point(20, 34)
$folderCodeLabel.ForeColor = $themeText
$inputPanel.Controls.Add($folderCodeLabel)

$folderCodeBox = New-Object System.Windows.Forms.TextBox
$folderCodeBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$folderCodeBox.Size = New-Object System.Drawing.Size(340, 30)
$folderCodeBox.Location = New-Object System.Drawing.Point(145, 30)
$inputPanel.Controls.Add($folderCodeBox)

$uidLabel = New-Object System.Windows.Forms.Label
$uidLabel.Text = "Folder UID:"
$uidLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$uidLabel.AutoSize = $true
$uidLabel.Location = New-Object System.Drawing.Point(20, 67)
$uidLabel.ForeColor = $themeText
$inputPanel.Controls.Add($uidLabel)

$uidBox = New-Object System.Windows.Forms.TextBox
$uidBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$uidBox.Size = New-Object System.Drawing.Size(340, 30)
$uidBox.Location = New-Object System.Drawing.Point(145, 63)
$inputPanel.Controls.Add($uidBox)

$getFolderButton = New-GreenButton -Text "Get UID" -X 535 -Y 30 -W 170 -H 30
$inputPanel.Controls.Add($getFolderButton)

$startButton = New-GreenButton -Text "Create" -X 535 -Y 63 -W 170 -H 30
$inputPanel.Controls.Add($startButton)

$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.BackColor = $themeWaitingBg
$statusPanel.Location = New-Object System.Drawing.Point(30, 290)
$statusPanel.Size = New-Object System.Drawing.Size(880, 38)
$form.Controls.Add($statusPanel)
Add-GreenBorder -Control $statusPanel

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: Waiting for Folder Code or Folder UID"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(14, 9)
$statusLabel.ForeColor = $themeWaitingText
$statusPanel.Controls.Add($statusLabel)

$logTitle = New-Object System.Windows.Forms.Label
$logTitle.Text = "Activity Log"
$logTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$logTitle.AutoSize = $true
$logTitle.Location = New-Object System.Drawing.Point(32, 342)
$logTitle.ForeColor = $themeText
$form.Controls.Add($logTitle)


$logBorderPanel = New-Object System.Windows.Forms.Panel
$logBorderPanel.BackColor = $themeGreen
$logBorderPanel.Location = New-Object System.Drawing.Point(29, 367)
$logBorderPanel.Size = New-Object System.Drawing.Size(882, 349)
$form.Controls.Add($logBorderPanel)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$logBox.ReadOnly = $true
$logBox.WordWrap = $false
$logBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$logBox.BackColor = [System.Drawing.Color]::White
$logBox.ForeColor = $themeText
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$logBox.Size = New-Object System.Drawing.Size(878, 345)
$logBox.Location = New-Object System.Drawing.Point(2, 2)
$logBorderPanel.Controls.Add($logBox)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear Logs"
$clearButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$clearButton.Size = New-Object System.Drawing.Size(130, 34)
$clearButton.Location = New-Object System.Drawing.Point(640, 728)
$clearButton.BackColor = [System.Drawing.Color]::White
$clearButton.ForeColor = $themeGreenDark
$clearButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$clearButton.FlatAppearance.BorderColor = $themeGreen
$clearButton.FlatAppearance.BorderSize = 1
$form.Controls.Add($clearButton)
Add-WhiteGreenHover -Button $clearButton

$openLogsButton = New-Object System.Windows.Forms.Button
$openLogsButton.Text = "Open Logs"
$openLogsButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$openLogsButton.Size = New-Object System.Drawing.Size(130, 34)
$openLogsButton.Location = New-Object System.Drawing.Point(780, 728)
$openLogsButton.BackColor = [System.Drawing.Color]::White
$openLogsButton.ForeColor = $themeGreenDark
$openLogsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$openLogsButton.FlatAppearance.BorderColor = $themeGreen
$openLogsButton.FlatAppearance.BorderSize = 1
$form.Controls.Add($openLogsButton)
Add-WhiteGreenHover -Button $openLogsButton

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

function Write-UiLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logBox.AppendText("[$timestamp] $Message" + [Environment]::NewLine)
    $script:GuiLastAppendedBlank = $false
    $logBox.SelectionStart = $logBox.Text.Length
    $logBox.ScrollToCaret()
}

function Should-ShowLineInGui {
    param(
        [string]$Line,
        [bool]$IsSyncRunLog = $true
    )

    if ([string]::IsNullOrWhiteSpace($Line)) { return $false }
    if (-not $IsSyncRunLog) { return $true }

    $trimmed = $Line.Trim()

    if ($trimmed -imatch "risk level") { return $false }

    $hiddenStartsWith = @(
        "[InventoryAgent]",
        "[RuntimeContextAgent]",
        "[TemplateStructureAgent] Resolving template structure",
        "[TemplateStructureAgent] Risk level"
    )

    foreach ($prefix in $hiddenStartsWith) {
        if ($trimmed.StartsWith($prefix)) { return $false }
    }

    $noPrefix = ($trimmed -replace '^\[[^\]]+\]\s*', '')

    if ($noPrefix.StartsWith("Plan summary")) {
        if (-not $script:GuiPlanSummaryShown) {
            $script:GuiPlanSummaryShown = $true
            $script:GuiInsidePlanSummary = $true
            $script:GuiSkipDuplicatePlanSummary = $false
            return $true
        }

        $script:GuiInsidePlanSummary = $true
        $script:GuiSkipDuplicatePlanSummary = $true
        return $false
    }

    if ($noPrefix.StartsWith("Areas:") -or
        $noPrefix.StartsWith("Lines:") -or
        $noPrefix.StartsWith("Machines:") -or
        $noPrefix.StartsWith("Operators:")) {
        if ($script:GuiInsidePlanSummary -and -not $script:GuiSkipDuplicatePlanSummary) {
            return $true
        }

        return $false
    }

    if ($script:GuiInsidePlanSummary) {
        $script:GuiInsidePlanSummary = $false
        $script:GuiSkipDuplicatePlanSummary = $false
    }

    $showContains = @(
        "TiCon Sync Started",
        "Folder UID:",
        "Project Root:",
        "Build skipped",
        "Status: completed",
        "Full process completed successfully",
        "Template structure OK",
        "Nothing to create",
        "Execution complete",
        "Areas to create:",
        "Areas created:",
        "Area created:",
        "Lines to create:",
        "Lines created:",
        "Line created:",
        "Machines to create:",
        "Machines created in batch:",
        "Machines created:",
        "Machines checked:",
        "Operators to create:",
        "Operators created in batch:",
        "Operators created:",
        "Operators checked:",
        "Station Runner Started",
        "Stations from Excel",
        "Existing stations in PEH",
        "Stations created in batch",
        "Stations checked",
        "Stations created",
        "Stations updated",
        "Station Runner Completed",
        "Error",
        "failed",
        "ECONNRESET"
    )

    if ($trimmed.StartsWith("[Step")) { return $true }

    foreach ($token in $showContains) {
        if ($trimmed.Contains($token)) { return $true }
    }

    return $false
}

function Format-GuiLogLine {
    param(
        [string]$Line,
        [bool]$IsSyncRunLog = $true
    )

    if ([string]::IsNullOrWhiteSpace($Line)) { return "" }

    $formatted = $Line.TrimEnd()

    if ($IsSyncRunLog -and -not $formatted.TrimStart().StartsWith("[Step")) {
        # Remove internal agent prefixes for cleaner phase summary display.
        $formatted = ($formatted -replace '^\[[^\]]+\]\s*', '')
    }

    $formatted = $formatted.TrimEnd()

    if ($formatted.TrimStart().StartsWith("[Step")) {
        return $formatted.TrimStart()
    }

    $noIndentStarts = @(
        "TiCon Sync Started",
        "Folder UID:",
        "Project Root:",
        "Full process completed successfully",
        "[Folder Search]",
        "Folder code:"
    )

    foreach ($prefix in $noIndentStarts) {
        if ($formatted.TrimStart().StartsWith($prefix)) {
            return $formatted.TrimStart()
        }
    }

    $trimmedStart = $formatted.TrimStart()
    if ($trimmedStart.StartsWith("Areas:") -or
        $trimmedStart.StartsWith("Lines:") -or
        $trimmedStart.StartsWith("Machines:") -or
        $trimmedStart.StartsWith("Operators:")) {
        return "  $trimmedStart"
    }

    if (-not $formatted.StartsWith("  ")) {
        return "  $trimmedStart"
    }

    return $formatted
}

function Append-LogFileContent {
    param([string]$FilePath, [ref]$LastLength)
    if ([string]::IsNullOrWhiteSpace($FilePath)) { return }
    if (-not (Test-Path $FilePath)) { return }
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { return }
    if ($content.Length -le $LastLength.Value) { return }
    $newText = $content.Substring($LastLength.Value)
    $LastLength.Value = $content.Length
    $isSyncRunLog = ($FilePath -eq $script:LogFilePath)

    foreach ($line in ($newText -split "`r?`n")) {
        if (-not (Should-ShowLineInGui -Line $line -IsSyncRunLog $isSyncRunLog)) { continue }

        $formattedLine = Format-GuiLogLine -Line $line -IsSyncRunLog $isSyncRunLog
        if ([string]::IsNullOrWhiteSpace($formattedLine)) { continue }

        if ($formattedLine.StartsWith("[Step") -and -not $script:GuiLastAppendedBlank -and $logBox.TextLength -gt 0) {
            $logBox.AppendText([Environment]::NewLine)
            $script:GuiLastAppendedBlank = $true
        }

        $logBox.AppendText($formattedLine + [Environment]::NewLine)
        $script:GuiLastAppendedBlank = $false
    }

    $logBox.SelectionStart = $logBox.Text.Length
    $logBox.ScrollToCaret()
}

function Append-NewLogContent { Append-LogFileContent -FilePath $script:LogFilePath -LastLength ([ref]$script:LastLogLength) }
function Append-NewFolderSearchLogContent { Append-LogFileContent -FilePath $script:FolderSearchLogFilePath -LastLength ([ref]$script:FolderSearchLastLogLength) }

function Create-FolderSearchCmdFile {
    param([string]$FolderCode)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $guiArtifactDir = Join-Path $script:ProjectRoot "artifacts\gui"
    if (-not (Test-Path $guiArtifactDir)) { New-Item -Path $guiArtifactDir -ItemType Directory -Force | Out-Null }
    $script:FolderSearchCmdFilePath = Join-Path $guiArtifactDir "ticon_folder_search_$timestamp.cmd"
    $script:FolderSearchLogFilePath = Join-Path $guiArtifactDir "ticon_folder_search_$timestamp.log"
    $cmdLines = @(
        "@echo off",
        "cd /d `"$script:ProjectRoot`"",
        "echo [Folder Search] > `"$script:FolderSearchLogFilePath`"",
        "echo   Folder code: $FolderCode >> `"$script:FolderSearchLogFilePath`"",
        "echo. >> `"$script:FolderSearchLogFilePath`"",
        "if not exist dist\pipeline\searchFolder.js call npm run -s build >> `"$script:FolderSearchLogFilePath`" 2>&1",
        "if errorlevel 1 exit /b 1",
        "node dist\pipeline\searchFolder.js `"$FolderCode`" >> `"$script:FolderSearchLogFilePath`" 2>&1",
        "if errorlevel 1 exit /b 1",
        "exit /b 0"
    )
    Set-Content -Path $script:FolderSearchCmdFilePath -Value $cmdLines -Encoding ASCII
    return $script:FolderSearchCmdFilePath
}

function Start-FolderSearchProcess {
    param([string]$FolderCode)
    $cmdFile = Create-FolderSearchCmdFile -FolderCode $FolderCode
    if (Test-Path $script:FolderSearchLogFilePath) { Remove-Item -Path $script:FolderSearchLogFilePath -Force }
    New-Item -Path $script:FolderSearchLogFilePath -ItemType File -Force | Out-Null
    $script:FolderSearchLastLogLength = 0
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c `"$cmdFile`""
    $psi.WorkingDirectory = $script:ProjectRoot
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $script:FolderSearchProcess = New-Object System.Diagnostics.Process
    $script:FolderSearchProcess.StartInfo = $psi
    if (-not $script:FolderSearchProcess.Start()) { throw "Failed to start folder search process." }
}

function Remove-FolderSearchCmdFile {
    if (-not [string]::IsNullOrWhiteSpace($script:FolderSearchCmdFilePath) -and (Test-Path $script:FolderSearchCmdFilePath)) {
        Remove-Item -Path $script:FolderSearchCmdFilePath -Force -ErrorAction SilentlyContinue
    }
}

function Create-RunnerCmdFile {
    param([string]$FolderUid)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $guiArtifactDir = Join-Path $script:ProjectRoot "artifacts\gui"
    if (-not (Test-Path $guiArtifactDir)) { New-Item -Path $guiArtifactDir -ItemType Directory -Force | Out-Null }
    $script:CmdFilePath = Join-Path $guiArtifactDir "ticon_gui_runner_$timestamp.cmd"
    $script:LogFilePath = Join-Path $guiArtifactDir "ticon_gui_run_$timestamp.log"
    $mockResponseFile = Join-Path $guiArtifactDir "mock_llm_response_$timestamp.json"
    $cmdLines = @(
        "@echo off",
        "cd /d `"$script:ProjectRoot`"",
        "echo TiCon Sync Started > `"$script:LogFilePath`"",
        "echo Folder UID: $FolderUid >> `"$script:LogFilePath`"",
        "echo Project Root: $script:ProjectRoot >> `"$script:LogFilePath`"",
        "echo. >> `"$script:LogFilePath`"",
        "echo [Step 1] Build check >> `"$script:LogFilePath`"",
        "if not exist dist\cli.js goto build_required",
        "if not exist dist\pipeline\fullSyncRunner.js goto build_required",
        "if not exist dist\pipeline\generateMockLLMResponse.js goto build_required",
        "echo Build skipped: existing build found >> `"$script:LogFilePath`"",
        "echo. >> `"$script:LogFilePath`"",
        "goto step2",
        ":build_required",
        "echo Building TypeScript project >> `"$script:LogFilePath`"",
        "call npm run -s build >> `"$script:LogFilePath`" 2>&1",
        "if errorlevel 1 exit /b 1",
        "echo   Status: completed >> `"$script:LogFilePath`"",
        "echo. >> `"$script:LogFilePath`"",
        ":step2",
        "echo [Step 2] Generate LLM Plan Response >> `"$script:LogFilePath`"",
        "node dist\pipeline\generateMockLLMResponse.js `"$FolderUid`" > `"$mockResponseFile`" 2>> `"$script:LogFilePath`"",
        "if errorlevel 1 exit /b 1",
        "echo   Status: completed >> `"$script:LogFilePath`"",
        "echo. >> `"$script:LogFilePath`"",
        ":step3",
        "echo [Step 3] Full Sync >> `"$script:LogFilePath`"",
        "set USE_LLM_PLAN=true",
        "set LLM_PLAN_RESPONSE_FILE=$mockResponseFile",
        "set FULLSYNC_PLAN_ONLY=",
        "set LLM_PLAN_RESPONSE=",
        "set ALLOW_LLM_FALLBACK_EXECUTION=",
        "node dist\pipeline\fullSyncRunner.js `"$FolderUid`" >> `"$script:LogFilePath`" 2>&1",
        "if errorlevel 1 exit /b 1",
        "echo   Status: completed >> `"$script:LogFilePath`"",
        "echo. >> `"$script:LogFilePath`"",
        "echo Full process completed successfully >> `"$script:LogFilePath`"",
        "exit /b 0"
    )
    Set-Content -Path $script:CmdFilePath -Value $cmdLines -Encoding ASCII
    return $script:CmdFilePath
}

function Remove-RunnerCmdFile {
    if (-not [string]::IsNullOrWhiteSpace($script:CmdFilePath) -and (Test-Path $script:CmdFilePath)) {
        Remove-Item -Path $script:CmdFilePath -Force -ErrorAction SilentlyContinue
    }
}

function Start-SyncProcess {
    param([string]$FolderUid)
    $cmdFile = Create-RunnerCmdFile -FolderUid $FolderUid
    if (Test-Path $script:LogFilePath) { Remove-Item -Path $script:LogFilePath -Force }
    New-Item -Path $script:LogFilePath -ItemType File -Force | Out-Null
    $script:LastLogLength = 0
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c `"$cmdFile`""
    $psi.WorkingDirectory = $script:ProjectRoot
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $script:RunProcess = New-Object System.Diagnostics.Process
    $script:RunProcess.StartInfo = $psi
    if (-not $script:RunProcess.Start()) { throw "Failed to start sync process." }
}

function Set-UiEnabled {
    param([bool]$Enabled)
    $getFolderButton.Enabled = $Enabled
    $startButton.Enabled = $Enabled
    $clearButton.Enabled = $Enabled
    $openLogsButton.Enabled = $Enabled
    $folderCodeBox.Enabled = $Enabled
    $uidBox.Enabled = $Enabled
}

$timer.Add_Tick({
    Append-NewFolderSearchLogContent
    Append-NewLogContent
    $hasActiveFolderSearch = $false
    $hasActiveSync = $false

    if ($null -ne $script:FolderSearchProcess) {
        if ($script:FolderSearchProcess.HasExited) {
            Append-NewFolderSearchLogContent
            $folderSearchExitCode = $script:FolderSearchProcess.ExitCode
            Remove-FolderSearchCmdFile
            $script:FolderSearchProcess = $null
            Set-UiEnabled -Enabled $true
            if ($folderSearchExitCode -eq 0) { Set-Status -Message "Folder search completed" -Type "Success" }
            else { Set-Status -Message "Folder search failed" -Type "Error"; Write-UiLog "Folder search failed with exit code $folderSearchExitCode" }
        } else { $hasActiveFolderSearch = $true }
    }

    if ($null -ne $script:RunProcess) {
        if ($script:RunProcess.HasExited) {
            Append-NewLogContent
            $exitCode = $script:RunProcess.ExitCode
            Remove-RunnerCmdFile
            $script:RunProcess = $null
            Set-UiEnabled -Enabled $true
            if ($exitCode -eq 0) {
                Set-Status -Message "Completed successfully" -Type "Success"
                Write-UiLog "Sync completed successfully"
                [System.Windows.Forms.MessageBox]::Show("TiCon hierarchy creation completed successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            } else {
                Set-Status -Message "Failed" -Type "Error"
                Write-UiLog "Sync failed with exit code $exitCode"
                [System.Windows.Forms.MessageBox]::Show("TiCon hierarchy creation failed. Please check logs.", "Execution Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            }
        } else { $hasActiveSync = $true }
    }

    if (-not $hasActiveFolderSearch -and -not $hasActiveSync) { $timer.Stop() }
})

$getFolderButton.Add_Click({
    $folderCode = $folderCodeBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($folderCode)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter Folder Code.", "Folder Code Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    Set-UiEnabled -Enabled $false
    Set-Status -Message "Searching folder" -Type "Working"
    Write-UiLog ""
    try { Start-FolderSearchProcess -FolderCode $folderCode; $timer.Start() }
    catch {
        Remove-FolderSearchCmdFile
        $script:FolderSearchProcess = $null
        Set-UiEnabled -Enabled $true
        Write-UiLog "  Folder search failed"
        Write-UiLog "  $($_.Exception.Message)"
        Set-Status -Message "Folder search failed" -Type "Error"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Folder Search Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$startButton.Add_Click({
    $uid = $uidBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($uid)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter Folder UID before starting.", "Folder UID Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        Set-Status -Message "Waiting for Folder UID" -Type "Working"
        return
    }
    if ($uid -notlike "Folder-*") { $uid = "Folder-$uid" }
    $logBox.Clear()
    $script:GuiLastAppendedBlank = $false
    $script:GuiPlanSummaryShown = $false
    $script:GuiInsidePlanSummary = $false
    $script:GuiSkipDuplicatePlanSummary = $false
    Set-UiEnabled -Enabled $false
    Set-Status -Message "Running" -Type "Working"
    Write-UiLog "TiCon hierarchy creation started"
    Write-UiLog "Folder UID: $uid"
    Write-UiLog "Project Root: $script:ProjectRoot"
    try { Start-SyncProcess -FolderUid $uid; $timer.Start() }
    catch {
        Remove-RunnerCmdFile
        $script:RunProcess = $null
        Set-UiEnabled -Enabled $true
        Write-UiLog "Process failed"
        Write-UiLog $_.Exception.Message
        Set-Status -Message "Failed" -Type "Error"
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Execution Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$clearButton.Add_Click({
    $logBox.Clear()
    $script:GuiLastAppendedBlank = $false
    $script:GuiPlanSummaryShown = $false
    $script:GuiInsidePlanSummary = $false
    $script:GuiSkipDuplicatePlanSummary = $false
    Set-Status -Message "Waiting for Folder Code or Folder UID" -Type "Waiting"
})

$openLogsButton.Add_Click({
    $guiArtifactDir = Join-Path $script:ProjectRoot "artifacts\gui"
    if (-not (Test-Path $guiArtifactDir)) { New-Item -Path $guiArtifactDir -ItemType Directory -Force | Out-Null }
    Start-Process explorer.exe $guiArtifactDir
})

[void]$form.ShowDialog()
