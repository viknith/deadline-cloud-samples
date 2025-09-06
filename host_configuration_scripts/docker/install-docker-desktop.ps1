# install-docker-desktop.ps1
# Single-phase Docker Desktop installation script for Windows EC2 instances
# Performs all installation steps and initializes Docker Engine

$scriptStartTime = Get-Date

Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Starting Docker installation process..."

# Step 1: Enable Containers feature (no restart)
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Installing Windows Containers feature..."
$containersFeature = Get-WindowsOptionalFeature -Online -FeatureName Containers
if ($containersFeature.State -eq "Disabled") {
    $featureStartTime = Get-Date
    Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
    $featureEndTime = Get-Date
    $featureDuration = ($featureEndTime - $featureStartTime).TotalSeconds
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Containers feature enabled in $([math]::Round($featureDuration, 2)) seconds"
} else {
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Containers feature already enabled"
}

# Step 2: Download Docker Desktop installer
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Downloading Docker Desktop installer from S3..."
$downloadStartTime = Get-Date

aws s3 cp --no-progress "s3://viknith-job-attachments/Installers/Docker Desktop Installer.exe" ".\Docker_Desktop_Installer.exe"

if (-not (Test-Path ".\Docker_Desktop_Installer.exe")) {
    Write-Error "[$((Get-Date).ToString('HH:mm:ss'))] Docker installer download failed - file not found"
    exit 1
}

$downloadEndTime = Get-Date
$downloadDuration = ($downloadEndTime - $downloadStartTime).TotalSeconds
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Download completed in $([math]::Round($downloadDuration, 2)) seconds"

# Step 3: Install Docker Desktop
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Installing Docker Desktop..."
$installStartTime = Get-Date
$process = Start-Process -FilePath ".\Docker_Desktop_Installer.exe" -ArgumentList "install --quiet --accept-license --backend=windows --always-run-service" -Wait -PassThru
$installEndTime = Get-Date
$installDuration = ($installEndTime - $installStartTime).TotalSeconds

# Exit codes 0 and 3 are considered success (3 = success but reboot required)
if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3) {
    Write-Error "[$((Get-Date).ToString('HH:mm:ss'))] Docker installation failed with exit code: $($process.ExitCode) after $([math]::Round($installDuration, 2)) seconds"
    exit 1
}

if ($process.ExitCode -eq 3) {
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Docker Desktop installed successfully (reboot required) in $([math]::Round($installDuration, 2)) seconds"
} else {
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Docker Desktop installed successfully in $([math]::Round($installDuration, 2)) seconds"
}

# Step 4: Add users to docker-users group and elevate deadline-worker
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Adding users to docker-users group..."
Add-LocalGroupMember -Group "docker-users" -Member "deadline-worker" -ErrorAction SilentlyContinue
Add-LocalGroupMember -Group "docker-users" -Member "ssm-user" -ErrorAction SilentlyContinue

Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Adding deadline-worker to Administrators group..."
Add-LocalGroupMember -Group "Administrators" -Member "deadline-worker" -ErrorAction SilentlyContinue

# Step 5: Add Docker CLI to system PATH
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Configuring Docker CLI PATH..."
$dockerPath = "C:\Program Files\Docker\Docker\resources\bin"
if (-not (Test-Path $dockerPath)) {
    Write-Warning "[$((Get-Date).ToString('HH:mm:ss'))] Docker CLI path not found: $dockerPath"
} else {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$dockerPath*") {
        [Environment]::SetEnvironmentVariable("PATH", $currentPath + ";$dockerPath", "Machine")
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Docker CLI added to system PATH"
    } else {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Docker CLI already in system PATH"
    }
}

# Step 6: Docker Desktop configuration complete
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Docker Desktop installation complete"
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Docker Desktop will manage its own engine after reboot"

$totalDuration = ($installEndTime - $scriptStartTime).TotalMinutes
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Installation complete in $([math]::Round($totalDuration, 2)) minutes"
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Rebooting to finalize Containers feature..."

# Clean up installer
Remove-Item ".\Docker_Desktop_Installer.exe" -ErrorAction SilentlyContinue

# Final reboot
Restart-Computer -Force