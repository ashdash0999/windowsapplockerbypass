cd C:\Windows\System32\Tasks
mkdir games -ErrorAction SilentlyContinue
$s=(New-Object -Com WScript.Shell).CreateShortcut("$HOME\music\games.lnk"); $s.TargetPath="C:\Windows\System32\Tasks\games"; $s.Save()
cd C:\Windows\System32\Tasks\games

& {
    Clear-Host
    $path = "$HOME\Downloads"
    $destination = "C:\Windows\System32\Tasks\games"
    $filesToCheck = @(
        @{name = "Geometry Dash"; file = "Geometry Dash.zip"; folder = "geometry dash"; url = "https://onedrive.live.com/personal/ec3a813b4f8bdfbf/_layouts/15/download.aspx?UniqueId=238be449%2D8828%2D4dc0%2Da00f%2D4b3d23426986"},
        @{name = "Tor"; file = "Tor.zip"; folder = "tor"; url = "https://onedrive.live.com/personal/ec3a813b4f8bdfbf/_layouts/15/download.aspx?UniqueId=7cf93356%2Db19b%2D46e1%2D84b8%2D50ddc83fbc81"}
    )

    if (!(Test-Path $destination)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }

    function Try-Expand {
        param($zip, $out)
        try {
            Expand-Archive -LiteralPath $zip -DestinationPath $out -Force -ErrorAction Stop
            return $true
        } catch {
            return $false
        }
    }

    function Try-ShellExtract {
        param($zip, $out)
        try {
            $shell = New-Object -ComObject Shell.Application
            $zipFolder = $shell.NameSpace($zip)
            $destFolder = $shell.NameSpace($out)
            if (-not $zipFolder -or -not $destFolder) { return $false }
            $destFolder.CopyHere($zipFolder.Items(), 0x10)
            # wait short time for items to appear
            $wait = 0
            while ((Get-ChildItem -LiteralPath $out -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 -and $wait -lt 10) {
                Start-Sleep -Milliseconds 300
                $wait++
            }
            return ((Get-ChildItem -LiteralPath $out -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)
        } catch {
            return $false
        }
    }

    Write-Host "-------------------------------------------" -ForegroundColor Cyan
    Write-Host "   CHECKING FOR EXISTING FILES..." -ForegroundColor White -BackgroundColor Blue
    Write-Host "-------------------------------------------`n" -ForegroundColor Cyan

    $filesToProcess = @()

    foreach ($file in $filesToCheck) {
        $filePath = Join-Path $path $file.file
        if (Test-Path $filePath) {
            Write-Host "[✓] Found: $($file.name) ($($file.file))" -ForegroundColor Green
            $filesToProcess += $file
        } else {
            Write-Host "[✗] Missing: $($file.name) ($($file.file))" -ForegroundColor Yellow
        }
    }

    if ($filesToProcess.Count -lt $filesToCheck.Count) {
        Write-Host "`n[!] Opening download pages for missing files in your browser and waiting for them to appear in Downloads..." -ForegroundColor Cyan

        foreach ($file in $filesToCheck) {
            $filePath = Join-Path $path $file.file
            if (Test-Path $filePath) { continue }

            Write-Host "`n[*] Opening download URL for: $($file.name)" -ForegroundColor Magenta
            Start-Process $file.url

            Write-Host "Please download '$($file.file)' from the opened page and save it to: $path" -ForegroundColor White -BackgroundColor DarkBlue

            # Auto-poll for the file with timeout, then prompt if not found
            $maxWaitSeconds = 300    # 5 minutes timeout (adjust if needed)
            $intervalSeconds = 2
            $elapsed = 0
            while (-not (Test-Path $filePath) -and ($elapsed -lt $maxWaitSeconds)) {
                Start-Sleep -Seconds $intervalSeconds
                $elapsed += $intervalSeconds
            }

            if (Test-Path $filePath) {
                Write-Host "[✓] Found downloaded file: $($file.file)" -ForegroundColor Green
                $filesToProcess += $file
                continue
            }

            # if timeout reached and file not found, give user options
            Write-Host "[!] File not detected in $path after $maxWaitSeconds seconds." -ForegroundColor Yellow
            $choice = Read-Host "Type 'open' to reopen the download page, 'retry' to keep waiting, or 'skip' to skip this file (open/retry/skip)"
            switch ($choice.ToLower()) {
                'open' {
                    Start-Process $file.url
                    # reset timer and poll again
                    $elapsed = 0
                    while (-not (Test-Path $filePath) -and ($elapsed -lt $maxWaitSeconds)) {
                        Start-Sleep -Seconds $intervalSeconds
                        $elapsed += $intervalSeconds
                    }
                    if (Test-Path $filePath) {
                        Write-Host "[✓] Found downloaded file: $($file.file)" -ForegroundColor Green
                        $filesToProcess += $file
                    } else {
                        Write-Host "[!] Still not found. Skipping $($file.name)." -ForegroundColor Yellow
                    }
                }
                'retry' {
                    # poll once more with same timeout
                    $elapsed = 0
                    while (-not (Test-Path $filePath) -and ($elapsed -lt $maxWaitSeconds)) {
                        Start-Sleep -Seconds $intervalSeconds
                        $elapsed += $intervalSeconds
                    }
                    if (Test-Path $filePath) {
                        Write-Host "[✓] Found downloaded file: $($file.file)" -ForegroundColor Green
                        $filesToProcess += $file
                    } else {
                        Write-Host "[!] Still not found. Skipping $($file.name)." -ForegroundColor Yellow
                    }
                }
                default {
                    Write-Host "[!] Skipping $($file.name) by user choice." -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "`n[✓] All files found. Using existing files." -ForegroundColor Green
    }

    Write-Host "`n-------------------------------------------" -ForegroundColor Cyan
    Write-Host "   EXTRACTING AND MOVING FILES..." -ForegroundColor White -BackgroundColor Blue
    Write-Host "-------------------------------------------`n" -ForegroundColor Cyan

    $total = $filesToProcess.Count
    $index = 0

    foreach ($file in $filesToProcess) {
        $index++
        Write-Host "-------------------------------------------" -ForegroundColor DarkCyan
        Write-Host "[File $index of $total] $($file.name)" -ForegroundColor Cyan
        $filePath = Join-Path $path $file.file
        if (-not (Test-Path $filePath)) {
            Write-Host "[!] File not found: $filePath -- skipping" -ForegroundColor Yellow
            continue
        }

        # use a temp extraction folder unique per item
        $tempExtract = Join-Path $path ("_extract_" + ($file.folder -replace '\s','_') + "_" + (Get-Random -Maximum 99999))
        if (Test-Path $tempExtract) { Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $tempExtract | Out-Null

        $extractedOk = $false
        # Try Expand-Archive first (fast for store zips)
        if (Try-Expand -zip $filePath -out $tempExtract) {
            $extractedOk = $true
            Write-Host "[✓] Extracted with Expand-Archive" -ForegroundColor Green
        } else {
            Write-Host "[!] Expand-Archive failed or unsupported. Falling back to Shell.Application..." -ForegroundColor Yellow
            if (Try-ShellExtract -zip $filePath -out $tempExtract) {
                $extractedOk = $true
                Write-Host "[✓] Extracted with Shell.Application" -ForegroundColor Green
            } else {
                Write-Host "[✗] Extraction failed for $($file.file). Skipping." -ForegroundColor Red
            }
        }

        if (-not $extractedOk) {
            # cleanup temp and continue
            Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
            continue
        }

        # Wait briefly for NTFS to flush (very short since store zips are quick)
        Start-Sleep -Milliseconds 300

        # Decide what to move:
        $children = Get-ChildItem -LiteralPath $tempExtract -Force -ErrorAction SilentlyContinue
        $folderDestination = Join-Path $destination $file.folder

        if ($children.Count -eq 1 -and $children[0].PSIsContainer) {
            $singleDir = $children[0].FullName
            Write-Host "[*] Zip contained a single folder: '$($children[0].Name)'" -ForegroundColor Cyan
            # move the single directory to the destination (rename to expected folder name if different)
            if (Test-Path $folderDestination) { Remove-Item -LiteralPath $folderDestination -Recurse -Force -ErrorAction SilentlyContinue }
            try {
                Move-Item -LiteralPath $singleDir -Destination $folderDestination -Force
                Write-Host "[✓] Moved folder to: $folderDestination" -ForegroundColor Green
            } catch {
                Write-Host "[✗] Move failed: $($_.Exception.Message)" -ForegroundColor Red
                # attempt moving contents instead
                New-Item -ItemType Directory -Path $folderDestination -Force | Out-Null
                Get-ChildItem -LiteralPath $singleDir -Force | ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination $folderDestination -Force }
                Remove-Item -LiteralPath $singleDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "[✓] Moved contents to: $folderDestination" -ForegroundColor Green
            }
        } elseif ($children.Count -gt 0) {
            Write-Host "[*] Zip contained $($children.Count) item(s) at root. Moving contents into '$($file.folder)'" -ForegroundColor Cyan
            if (Test-Path $folderDestination) { Remove-Item -LiteralPath $folderDestination -Recurse -Force -ErrorAction SilentlyContinue }
            New-Item -ItemType Directory -Path $folderDestination -Force | Out-Null
            Get-ChildItem -LiteralPath $tempExtract -Force | ForEach-Object {
                try { Move-Item -LiteralPath $_.FullName -Destination $folderDestination -Force -ErrorAction Stop }
                catch { Write-Host "[!] Could not move item $($_.Name): $($_.Exception.Message)" -ForegroundColor Yellow }
            }
            Write-Host "[✓] Moved contents to: $folderDestination" -ForegroundColor Green
        } else {
            Write-Host "[!] Extraction produced no items. Skipping move." -ForegroundColor Yellow
        }

        # Clean up temp
        Start-Sleep -Milliseconds 200
        Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

        # short pause ensures the file system has settled before next loop
        Start-Sleep -Milliseconds 400
    }

    Write-Host "`nAll processing done. Verifying results..." -ForegroundColor Magenta
    foreach ($file in $filesToCheck) {
        $folderDestination = Join-Path $destination $file.folder
        if (Test-Path $folderDestination) {
            Write-Host "[✓] $($file.name) -> $folderDestination" -ForegroundColor Green
        } else {
            Write-Host "[✗] $($file.name) NOT found at $folderDestination" -ForegroundColor Yellow
        }
    }

    Write-Host "`nTransfer complete. Closing in 4 seconds..." -ForegroundColor Magenta
    Start-Sleep -Seconds 4
}
