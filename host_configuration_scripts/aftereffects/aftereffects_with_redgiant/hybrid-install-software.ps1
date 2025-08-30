# Zip-based Software Installation Script
# Downloads zip files from S3 and extracts to Program Files
$ErrorActionPreference = "Stop"

# Script Configuration Variables
$is_cmf = $false  # Set to $true for Customer Managed Fleet (CMF)
$vpc_endpoint = "vpce-07359508fe8e4d605-sznn09sg.vpce-svc-0c4b155bc5b761304.us-west-2.vpce.amazonaws.com"  # Replace with actual VPC endpoint for CMF
$INSTALLER_S3_BUCKET = "viknith-job-attachments"  # Your S3 bucket name
$REDGIANT_ZIP = "Red_Giant_Windows_installation.zip"
$MAXON_ZIP = "Maxon_Windows_installation.zip"
$ADOBE_ZIP = "Adobe_Windows_installation.zip"

# Paths
$downloadsPath = "C:\Temp"
$programFilesPath = "C:\Program Files"

# Start timing
$scriptStartTime = Get-Date

# Create temp directory if it doesn't exist
if (-not (Test-Path $downloadsPath)) {
    New-Item -ItemType Directory -Path $downloadsPath -Force
}

Write-Host "Setting system environment variables..."

[System.Environment]::SetEnvironmentVariable("MAXON_RENDERONLY", "true", [System.EnvironmentVariableTarget]::Machine)

# Set Red Giant license server for Customer Managed Fleet (CMF)
if ($is_cmf) {
    Write-Host "Setting Red Giant license server for CMF..."
    [System.Environment]::SetEnvironmentVariable("redshift_LICENSE", "7055@$vpc_endpoint", [System.EnvironmentVariableTarget]::Machine)
}

# Download and extract in parallel
Write-Host "Downloading and extracting files in parallel..."

# Red Giant: download and extract job
$redGiantJob = Start-Job -ScriptBlock {
    param($bucket, $file, $downloadPath, $extractPath)
    $zipFile = "$downloadPath\$file"
    aws s3 cp --no-progress "s3://$bucket/Installers/$file" $zipFile
    if (-not (Test-Path $zipFile)) { throw "Red Giant zip download failed" }
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
} -ArgumentList $INSTALLER_S3_BUCKET, $REDGIANT_ZIP, $downloadsPath, $programFilesPath

# Maxon: download and extract job
$maxonJob = Start-Job -ScriptBlock {
    param($bucket, $file, $downloadPath, $extractPath)
    $zipFile = "$downloadPath\$file"
    aws s3 cp --no-progress "s3://$bucket/Installers/$file" $zipFile
    if (-not (Test-Path $zipFile)) { throw "Maxon zip download failed" }
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
} -ArgumentList $INSTALLER_S3_BUCKET, $MAXON_ZIP, $downloadsPath, $programFilesPath

# Adobe: download and extract job (I'm pretty sure this is not needed but I did it just in case)
$adobeJob = Start-Job -ScriptBlock {
    param($bucket, $file, $downloadPath, $extractPath)
    $zipFile = "$downloadPath\$file"
    aws s3 cp --no-progress "s3://$bucket/Installers/$file" $zipFile
    if (-not (Test-Path $zipFile)) { throw "Adobe zip download failed" }
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
} -ArgumentList $INSTALLER_S3_BUCKET, $ADOBE_ZIP, $downloadsPath, $programFilesPath

# Wait for Red Giant job to complete, then start service
Write-Host "Waiting for Red Giant installation to complete..."
Wait-Job $redGiantJob | Out-Null
Remove-Job $redGiantJob

Write-Host "Starting Red Giant Service..."
Start-Process -FilePath "C:\Program Files\Red Giant\Services\Red Giant Service.exe" -ArgumentList "--noservice"

# Wait for Maxon job to complete
Write-Host "Waiting for Maxon installation to complete..."
Wait-Job $maxonJob | Out-Null
Remove-Job $maxonJob

# Wait for Adobe job to complete
Write-Host "Waiting for Adobe installation to complete..."
Wait-Job $adobeJob | Out-Null
Remove-Job $adobeJob

Write-Host "All installations completed."

# Calculate total time
$scriptEndTime = Get-Date
$totalDuration = $scriptEndTime - $scriptStartTime
Write-Host "Installation completed in: $($totalDuration.ToString('hh\:mm\:ss'))"