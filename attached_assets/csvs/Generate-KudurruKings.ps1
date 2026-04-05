<#
    Generate-KudurruKings.ps1
    — GPT-5-Chat-Latest creative asset generator
    — Auto-resume + checkpointing + runspace parallel acceleration + safe CSV writes
#>

# =====================================================================
# CONFIGURATION
# =====================================================================
$model         = "gpt-5-chat-latest"
$inputFile     = "E:\KudurruKings\Kudurru-Kings\attached_assets\csvs\canva_bulk.csv"
$outputFile    = "E:\KudurruKings\Kudurru-Kings\attached_assets\csvs\EoE_Prompts.csv"
$logFile       = "E:\KudurruKings\Kudurru-Kings\attached_assets\csvs\Run_Log.txt"
$checkpoint    = "E:\KudurruKings\Kudurru-Kings\attached_assets\csvs\Checkpoint.txt"

$parallelism   = 3     # safe range: 3–4
$maxRetries    = 5
$baseDelay     = 60
$delayMin      = 5
$delayMax      = 15

$temperature         = 0.95
$top_p               = 0.9
$frequency_penalty   = 0.35
$presence_penalty    = 0.15
$max_output_tokens   = 2200

$renderNote = "Centered circular portrait, 584x577 px, transparent PNG background, face centered perfectly within circle, frontal or soft three-quarter view."

# =====================================================================
# PROMPT BUILDER
# =====================================================================
function Build-Prompt($name) {
@"
You are writing a 1,000–1,500 word **visual description** for an illustrated card
portrait in the *Echoes of Eridu* universe, for the **Kudurru Kings** game.

GOAL
- Deliver paint-ready, cinematic imagery that a concept artist can execute.
- Prioritize concrete **surfaces, materials, silhouette, anatomy, lighting**, and **ornament**.
- Keep **flow**: cohesive paragraphs (no lists), zero redundancy.

WORLD & TONE (STYLE DNA)
- Mesopotamian myth-tech fusion: gold and lapis inlays, obsidian, mirror-bronze, reed-fiber composites,
  cuneiform light glyphs, living geometry, liquid light veins, divine alloys, tar-fire embers, crystal lamina.
- Compositions are **circular portraits** with a calm, iconic presence; background is **transparent** (PNG intent).
- Armor/props allowed when cultural or symbolic; never generic.

CANONICAL RULES
- **Adamu** is the **only** true human. Everyone else must be **explicitly alien** in biology or substance.
- For non-human entities: depart clearly from human anatomy (e.g., crystalline dermis, mirrored chitin, halo organs,
  light-based circulation, layered reeds of metallic glass, segmented jaw architectures, non-ocular perception).
- Mention alien divergence explicitly at least once (e.g., “unlike human musculature…”).
- Avoid plot or backstory; this is a **visual sheet**.

BANNED / WEAK PHRASES:
- “otherworldly,” “ethereal,” “mysterious,” “arcane,” “it seems,” “perhaps,” “appears to”
- Repetitive color stacks like “shimmering, glowing, glistening”
- Repeating the same noun twice inside one sentence

COMPOSITION NOTE (append verbatim at the end):
"Centered circular portrait, 584x577 px, transparent PNG background, face centered perfectly within circle, frontal or soft three-quarter view."

TASK
Write the final description for **$name** only. Keep paragraphs flowing; no headings, no lists. Ensure ~1,000–1,500 words. Finish with the composition note verbatim.
"@
}

# =====================================================================
# LOAD CSV & RESUME SUPPORT
# =====================================================================
$csv = Import-Csv -Path $inputFile -Encoding UTF8
$total = $csv.Count

$completedNames = @()
if (Test-Path $outputFile) {
    try {
        $completedNames = (Import-Csv -Path $outputFile -Encoding UTF8 | Select-Object -ExpandProperty name)
        Write-Host "🔁 Found $($completedNames.Count) completed entries."
    } catch { Write-Warning "⚠️ Could not read existing output; starting fresh." }
}

$pendingRows = $csv | Where-Object { $_.name -and ($completedNames -notcontains $_.name) }

if (Test-Path $checkpoint) {
    try {
        $checkpointIndex = [int](Get-Content $checkpoint -Raw)
        if ($checkpointIndex -lt $pendingRows.Count) {
            $pendingRows = $pendingRows[$checkpointIndex..($pendingRows.Count - 1)]
            Write-Host "⏩ Resuming from checkpoint index $checkpointIndex"
        }
    } catch { Write-Warning "⚠️ Checkpoint unreadable, resuming from start of pending list" }
}

if ($pendingRows.Count -eq 0) {
    Write-Host "✅ All entries completed!"
    exit
}

Write-Host "📊 Ready to generate $($pendingRows.Count) of $total total characters."
Add-Content $logFile "[$(Get-Date)] Starting run with $($pendingRows.Count) pending of $total total."

# =====================================================================
# RUNSPACE POOL EXECUTION
# =====================================================================
Add-Type -AssemblyName System.Collections
$pool = [RunspaceFactory]::CreateRunspacePool(1, $parallelism)
$pool.ApartmentState = 'MTA'
$pool.Open()
$runspaces = @()

foreach ($row in $pendingRows) {
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $pool
    $null = $ps.AddScript({
        param($row,$model,$temperature,$top_p,$frequency_penalty,$presence_penalty,$max_output_tokens,$renderNote,$outputFile,$logFile,$checkpoint,$baseDelay,$maxRetries,$delayMin,$delayMax)

        function Build-Prompt {
            param($n)
@"
You are writing a 1,000–1,500 word **visual description** for an illustrated card portrait in the *Echoes of Eridu* universe, for the **Kudurru Kings** game.
TASK: Write the final description for **$n** only, ~1,000–1,500 words.
"@
        }

        $name = $row.name
        if (-not $name) { return }
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Add-Content $logFile "[$timestamp] Starting $name"

        $prompt = (Build-Prompt $name)
        $headers = @{ "Authorization" = "Bearer $env:OPENAI_API_KEY"; "Content-Type" = "application/json" }

        $body = @{
            model = $model
            messages = @(
                @{ role = "system"; content = "You are a professional narrative artist and world-builder. You write lavish, concrete, non-redundant visual prose that concept artists can paint from." },
                @{ role = "user";   content = $prompt }
            )
            temperature = $temperature
            top_p = $top_p
            frequency_penalty = $frequency_penalty
            presence_penalty = $presence_penalty
            max_tokens = $max_output_tokens
        } | ConvertTo-Json -Depth 7

        $response = $null
        for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
            try {
                $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
                            -Headers $headers -Method Post -Body $body -ErrorAction Stop
                break
            } catch {
                $msg = $_.Exception.Message
                if ($msg -match "429") {
                    $wait = [math]::Min($baseDelay * [math]::Pow(2, $attempt - 1), 900)
                    Add-Content $logFile "[$timestamp] ⚠️ Rate limited ($attempt/$maxRetries). Sleeping $wait s..."
                    Start-Sleep -Seconds $wait
                } elseif ($msg -match "401") {
                    Add-Content $logFile "[$timestamp] ❌ Unauthorized – check API key."
                    return
                } else {
                    Add-Content $logFile "[$timestamp] ❌ Error on $name : $msg"
                    return
                }
            }
        }

        if (-not $response) { return }
        $desc = $response.choices[0].message.content.Trim()

        $record = [PSCustomObject]@{
            name = $name
            description = $desc
            render_instructions = $renderNote
        }

        # --- Safe append using global mutex ---
        $mutex = New-Object System.Threading.Mutex($false, "Global\EoE_WriteLock")
        try {
            $null = $mutex.WaitOne()
            $tempCsv = Join-Path ([System.IO.Path]::GetTempPath()) ("eoe_" + [Guid]::NewGuid().ToString() + ".csv")
            $record | Export-Csv -Path $tempCsv -NoTypeInformation -Encoding UTF8

            if (-not (Test-Path $outputFile) -or (Get-Content $outputFile -TotalCount 1) -notmatch '^"name","description","render_instructions"$') {
                Copy-Item $tempCsv $outputFile -Force
            } else {
                $lines = Get-Content $tempCsv
                $lines[1..($lines.Count - 1)] | Add-Content -Path $outputFile -Encoding UTF8
            }

            Remove-Item $tempCsv -Force
            Add-Content $logFile "[$timestamp] ✅ Completed $name"

            # Update checkpoint safely
            $done = (Import-Csv $outputFile -ErrorAction SilentlyContinue).Count - 1
            Set-Content -Path $checkpoint -Value $done
        } finally {
            $mutex.ReleaseMutex()
            $mutex.Dispose()
        }

        Start-Sleep -Seconds (Get-Random -Minimum $delayMin -Maximum $delayMax)
    }).AddArgument($row).AddArgument($model).AddArgument($temperature).AddArgument($top_p).AddArgument($frequency_penalty).AddArgument($presence_penalty).AddArgument($max_output_tokens).AddArgument($renderNote).AddArgument($outputFile).AddArgument($logFile).AddArgument($checkpoint).AddArgument($baseDelay).AddArgument($maxRetries).AddArgument($delayMin).AddArgument($delayMax)

    $runspaces += @{ Pipe = $ps; Handle = $ps.BeginInvoke() }
}

# Progress monitor
while ($runspaces.Handle.IsCompleted -contains $false) {
    $done = (Import-Csv $outputFile -ErrorAction SilentlyContinue).Count - 1
    $pct = [math]::Round(($done / $total) * 100, 2)
    Write-Progress -Activity "Generating Kudurru Kings" -Status "$done of $total ($pct%) complete" -PercentComplete $pct
    Start-Sleep -Seconds 30
}

foreach ($r in $runspaces) { $r.Pipe.EndInvoke($r.Handle); $r.Pipe.Dispose() }
$pool.Close(); $pool.Dispose()

# =====================================================================
# END OF RUN
# =====================================================================
$endStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content $logFile "[$endStamp] 🏁 Run finished successfully."
Remove-Item $checkpoint -ErrorAction SilentlyContinue
Write-Host "`n✨ Generation complete at $endStamp"
Write-Host "📄 Output : $outputFile"
Write-Host "🪵 Log    : $logFile"
