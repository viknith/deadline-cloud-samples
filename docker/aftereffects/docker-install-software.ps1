# Sequential Software Installation Script
# Installs Adobe After Effects, Red Giant, and Universe from local installers
$ErrorActionPreference = "Stop"

# Script Configuration Variables - Update these for your environment
$is_cmf = $false  # Set to $true for Customer Managed Fleet (CMF), $false for Service Managed Fleet (SMF)
$vpc_endpoint = "<vpc_endpoint>"  # Replace with actual VPC endpoint for CMF Red Giant license server
$AE_VERSION = "2025"  # After Effects version year
$AE_INSTALLER = "After Effects_en_US_WIN_64.zip"
$REDGIANT_INSTALLER = "RedGiant-2025.6.0-Win.exe"
$UNIVERSE_INSTALLER = "Universe-2025.3.3_Win.exe"
$MAXON_APP_INSTALLER = "Maxon_App_2025.4.2_Win.exe"
$WEBVIEW2_INSTALLER = "MicrosoftEdgeWebView2RuntimeInstallerX64.exe"

# Paths
$AE_LOCATION = "C:\Program Files\Adobe\Adobe After Effects $AE_VERSION\Support Files"
$installersPath = "C:\installers"  # Where installers are copied in the container
$tempPath = "C:\Temp"

# Start overall timing
$scriptStartTime = Get-Date

# Set render-only env variable for Maxon One to pick up and aerender.exe path variable for submitter
Write-Host "Setting environment variables for rendering..."
[System.Environment]::SetEnvironmentVariable("AERENDER_EXECUTABLE", "$AE_LOCATION\aerender.exe", [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("MAXON_RENDERONLY", "true", [System.EnvironmentVariableTarget]::Machine)

# Create temp directory for extractions
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

# Verify all installers exist
$copyStartTime = Get-Date
Write-Host "Verifying local installers..."
if (-not (Test-Path "$installersPath\$AE_INSTALLER")) { throw "After Effects installer not found: $installersPath\$AE_INSTALLER" }
if (-not (Test-Path "$installersPath\$REDGIANT_INSTALLER")) { throw "Red Giant installer not found: $installersPath\$REDGIANT_INSTALLER" }
if (-not (Test-Path "$installersPath\$MAXON_APP_INSTALLER")) { throw "Maxon App installer not found: $installersPath\$MAXON_APP_INSTALLER" }
if (-not (Test-Path "$installersPath\$UNIVERSE_INSTALLER")) { throw "Universe installer not found: $installersPath\$UNIVERSE_INSTALLER" }
if (-not (Test-Path "$installersPath\$WEBVIEW2_INSTALLER")) { throw "WebView2 Runtime installer not found: $installersPath\$WEBVIEW2_INSTALLER" }
$copyEndTime = Get-Date
$copyDuration = $copyEndTime - $copyStartTime
Write-Host "Installer verification completed in: $($copyDuration.ToString('hh\:mm\:ss'))"

# Microsoft Edge WebView2 Runtime Installation
$webview2StartTime = Get-Date
Write-Host "Starting Microsoft Edge WebView2 Runtime installation..."
Start-Process -FilePath "$installersPath\$WEBVIEW2_INSTALLER" -ArgumentList "/silent", "/install" -Wait
$webview2EndTime = Get-Date
$webview2Duration = $webview2EndTime - $webview2StartTime
Write-Host "Microsoft Edge WebView2 Runtime installation completed in: $($webview2Duration.ToString('hh\:mm\:ss'))"

# After Effects Installation
$aeStartTime = Get-Date
Write-Host "Extracting After Effects zip file..."
Expand-Archive -Path "$installersPath\$AE_INSTALLER" -DestinationPath $tempPath -Force
Write-Host "Starting After Effects installation..."
if (-not (Test-Path "$tempPath\After Effects\Build\setup.exe")) { throw "After Effects installer not found after extraction" }
Start-Process -FilePath "$tempPath\After Effects\Build\setup.exe" -ArgumentList "--silent" -Wait
$aeEndTime = Get-Date
$aeDuration = $aeEndTime - $aeStartTime
Write-Host "After Effects installation completed in: $($aeDuration.ToString('hh\:mm\:ss'))"

# Maxon App Installation
$maxonStartTime = Get-Date
Write-Host "Starting Maxon App installation..."
Start-Process -FilePath "$installersPath\$MAXON_APP_INSTALLER" -ArgumentList "--mode", "unattended", "--unattendedmodeui", "none" -Wait
$maxonEndTime = Get-Date
$maxonDuration = $maxonEndTime - $maxonStartTime
Write-Host "Maxon App installation completed in: $($maxonDuration.ToString('hh\:mm\:ss'))"

# Red Giant Installation
$rgStartTime = Get-Date
Write-Host "Starting Red Giant installation..."
Start-Process -FilePath "$installersPath\$REDGIANT_INSTALLER" -ArgumentList "--mode", "unattended", "--unattendedmodeui", "none" -Wait
$rgEndTime = Get-Date
$rgDuration = $rgEndTime - $rgStartTime
Write-Host "Red Giant installation completed in: $($rgDuration.ToString('hh\:mm\:ss'))"

# Universe Installation
$universeStartTime = Get-Date
Write-Host "Starting Universe installation..."
Start-Process -FilePath "$installersPath\$UNIVERSE_INSTALLER" -ArgumentList "--mode", "unattended", "--unattendedmodeui", "none" -Wait
$universeEndTime = Get-Date
$universeDuration = $universeEndTime - $universeStartTime
Write-Host "Universe installation completed in: $($universeDuration.ToString('hh\:mm\:ss'))"

# Set Red Giant license server for Customer Managed Fleet (CMF)
if ($is_cmf) {
    Write-Host "Setting Red Giant license server for CMF..."
    [System.Environment]::SetEnvironmentVariable("redshift_LICENSE", "7055@$vpc_endpoint", [System.EnvironmentVariableTarget]::Machine)
}

# Calculate and display total time
$scriptEndTime = Get-Date
$totalDuration = $scriptEndTime - $scriptStartTime
Write-Host "=== Installation Summary ==="
Write-Host "Verification: $($copyDuration.ToString('hh\:mm\:ss'))"
Write-Host "WebView2 Runtime: $($webview2Duration.ToString('hh\:mm\:ss'))"
Write-Host "After Effects: $($aeDuration.ToString('hh\:mm\:ss'))"
Write-Host "Maxon App: $($maxonDuration.ToString('hh\:mm\:ss'))"
Write-Host "Red Giant: $($rgDuration.ToString('hh\:mm\:ss'))"
Write-Host "Universe: $($universeDuration.ToString('hh\:mm\:ss'))"
Write-Host "Total Time: $($totalDuration.ToString('hh\:mm\:ss'))"
Write-Host "All installations completed!"