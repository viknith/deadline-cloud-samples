$ErrorActionPreference = "Stop"

# S3 bucket configuration
$S3_BUCKET = "deadline-cloud-ae-installers"
$S3_REGION = "us-west-2"

# Installer file names (update these to match your S3 files)
$AE_INSTALLER = "After_Effects_2025_Win64.exe"
$REDGIANT_INSTALLER = "Red_Giant_2025_6_0_Universe_2025_3_3_installation.exe"
$MAXON_INSTALLER = "Maxon_App_Win_4.6.0.exe"

Write-Host "Starting software installation..."

# Create temp directory
New-Item -ItemType Directory -Path C:\temp -Force
Set-Location C:\temp

# Download installers from S3
Write-Host "Downloading After Effects installer..."
aws s3 cp s3://$S3_BUCKET/$AE_INSTALLER . --region $S3_REGION

Write-Host "Downloading Red Giant installer..."
aws s3 cp s3://$S3_BUCKET/$REDGIANT_INSTALLER . --region $S3_REGION

Write-Host "Downloading Maxon App installer..."
aws s3 cp s3://$S3_BUCKET/$MAXON_INSTALLER . --region $S3_REGION

# Install After Effects 2025 (silent install)
Write-Host "Installing After Effects 2025..."
Start-Process -FilePath ".\$AE_INSTALLER" -ArgumentList "--silent" -Wait -NoNewWindow

# Install Red Giant plugins (silent install)
Write-Host "Installing Red Giant plugins..."
Start-Process -FilePath ".\$REDGIANT_INSTALLER" -ArgumentList "/S" -Wait -NoNewWindow

# Install Maxon App (silent install)
Write-Host "Installing Maxon App..."
Start-Process -FilePath ".\$MAXON_INSTALLER" -ArgumentList "/S" -Wait -NoNewWindow

# Set environment variables
Write-Host "Setting environment variables..."
[Environment]::SetEnvironmentVariable("AERENDER_EXECUTABLE", "C:\Program Files\Adobe\Adobe After Effects 2025\Support Files\aerender.exe", "Machine")
[Environment]::SetEnvironmentVariable("MAXON_RENDERONLY", "true", "Machine")

# Clean up installers
Write-Host "Cleaning up temporary files..."
Remove-Item C:\temp\*.exe -Force

Write-Host "Software installation completed successfully!"