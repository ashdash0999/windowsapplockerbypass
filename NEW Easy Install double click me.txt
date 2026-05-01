cd C:\Windows\System32\Tasks
mkdir games
$s=(New-Object -Com WScript.Shell).CreateShortcut("$HOME\music\games.lnk"); $s.TargetPath="C:\Windows\System32\Tasks\games"; $s.Save()
cd C:\Windows\System32\Tasks\games
start "https://franklinpierceschools-my.sharepoint.com/personal/006691_fpsstudents_org/_layouts/15/download.aspx?UniqueId=5b1aab6b%2D3f10%2D4021%2D9b5a%2D2ced76a1c081"
start "https://franklinpierceschools-my.sharepoint.com/personal/006691_fpsstudents_org/_layouts/15/download.aspx?UniqueId=5d7cc960%2D1bd3%2D4bad%2Da4c9%2D747bc7b66b32"
cls
& {
    Clear-Host
    $path = "$HOME\Downloads"
    $destination = "C:\Windows\System32\Tasks\games"
    $targetFolders = @("tor", "geometry dash")

    # Make the games folder if it isn't already there
    if (!(Test-Path $destination)) { 
        New-Item -ItemType Directory -Path $destination -Force | Out-Null 
    }

    Write-Host "-------------------------------------------" -ForegroundColor Cyan
    Write-Host "   PLEASE UNZIP YOUR FILES IN DOWNLOADS   " -ForegroundColor White -BackgroundColor Blue
    Write-Host "-------------------------------------------`n" -ForegroundColor Cyan

    while ($targetFolders.Count -gt 0) {
        $foundFolders = @()
        foreach ($folderName in $targetFolders) {
            $fullPath = Join-Path $path $folderName
            
            if (Test-Path $fullPath -PathType Container) {
                Write-Host "`n[!] Detected: $folderName" -ForegroundColor Yellow
                $confirmation = Read-Host "Are the files done unzipping? (type 'y' for yes)"
                
                if ($confirmation.ToLower() -eq 'y') {
                    # Move the unzipped folder to the tasks/games location
                    Move-Item -Path $fullPath -Destination $destination -Force
                    Write-Host "Success! $folderName moved to system folder.`n" -ForegroundColor Green
                    $foundFolders += $folderName
                }
            }
        }
        # Update the list to only include folders not yet moved
        if ($foundFolders.Count -gt 0) {
            $targetFolders = $targetFolders | Where-Object { $_ -notin $foundFolders }
        }
        if ($targetFolders.Count -gt 0) { Start-Sleep -Seconds 2 }
    }

    Clear-Host
    Write-Host "`nTransfer complete. Closing..." -ForegroundColor Magenta
    Start-Sleep -Seconds 3
}
