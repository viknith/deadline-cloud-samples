# Zip-based Software Installation Script
# Downloads zip files from S3 and extracts to Program Files
$ErrorActionPreference = "Stop"

# Script Configuration Variables
$is_cmf = $false  # Set to $true for Customer Managed Fleet (CMF)
$vpc_endpoint = "vpce-07359508fe8e4d605-sznn09sg.vpce-svc-0c4b155bc5b761304.us-west-2.vpce.amazonaws.com"  # Replace with actual VPC endpoint for CMF
$INSTALLER_S3_BUCKET = "viknith-job-attachments"  # Your S3 bucket name
$REDGIANT_ZIP = "Red_Giant_Windows_installation.zip"
$MAXON_ZIP = "Maxon_Windows_installation.zip"

# Paths
$downloadsPath = "C:\Temp"
$programFilesPath = "C:\Program Files"

# Start timing
$scriptStartTime = Get-Date

# Create temp directory if it doesn't exist
if (-not (Test-Path $downloadsPath)) {
    New-Item -ItemType Directory -Path $downloadsPath -Force
}

# Download zip files from S3
Write-Host "Downloading zip files from S3..."
aws s3 cp --no-progress "s3://$INSTALLER_S3_BUCKET/$REDGIANT_ZIP" "$downloadsPath\$REDGIANT_ZIP"
if (-not (Test-Path "$downloadsPath\$REDGIANT_ZIP")) { throw "Red Giant zip download failed" }

aws s3 cp --no-progress "s3://$INSTALLER_S3_BUCKET/$MAXON_ZIP" "$downloadsPath\$MAXON_ZIP"
if (-not (Test-Path "$downloadsPath\$MAXON_ZIP")) { throw "Maxon zip download failed" }

# Extract Red Giant zip to Program Files
Write-Host "Extracting Red Giant to Program Files..."
Expand-Archive -Path "$downloadsPath\$REDGIANT_ZIP" -DestinationPath $programFilesPath -Force

# Extract Maxon zip to Program Files
Write-Host "Extracting Maxon to Program Files..."
Expand-Archive -Path "$downloadsPath\$MAXON_ZIP" -DestinationPath $programFilesPath -Force

# Start Red Giant Service executable
Write-Host "Starting Red Giant Service..."
Start-Process -FilePath "C:\Program Files\Red Giant\Services\Red Giant Service.exe" -WindowStyle Hidden

# Set Red Giant license server for Customer Managed Fleet (CMF)
if ($is_cmf) {
    Write-Host "Setting Red Giant license server for CMF..."
    [System.Environment]::SetEnvironmentVariable("redshift_LICENSE", "7055@$vpc_endpoint", [System.EnvironmentVariableTarget]::Machine)
}

# Calculate total time
$scriptEndTime = Get-Date
$totalDuration = $scriptEndTime - $scriptStartTime
Write-Host "Installation completed in: $($totalDuration.ToString('hh\:mm\:ss'))"