# PowerShell Script to Process Files with Delays

# Function to extract a zip file
function Extract-ZipFile {
    param (
        [string]$zipPath,
        [string]$destinationPath
    )
    Write-Host "Extracting $zipPath..."
    Expand-Archive -Path $zipPath -DestinationPath $destinationPath -Force
    Start-Sleep -Seconds 10 # Longer delay to ensure the extraction is complete
}

# Define paths
$zipFiles = @("Geometry Dash.zip", "Tor.zip")
$destination = "C:\ExtractedFiles"

# Create destination folder if it doesn't exist
if (!(Test-Path -Path $destination)) {
    New-Item -ItemType Directory -Path $destination
}

# Loop through each zip file and extract
foreach ($zipFile in $zipFiles) {
    Extract-ZipFile -zipPath $zipFile -destinationPath $destination
    Start-Sleep -Seconds 10 # Wait before moving to the next file
}

Write-Host "All files processed successfully!"