# docker-health-check.ps1
# Docker installation health check script for Windows EC2 instances
# Verifies Docker Desktop installation and functionality

Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Starting Docker health check..."

$healthStatus = @{
    "DockerDesktopInstalled" = $false
    "DockerCLIAvailable" = $false
    "DockerServiceRunning" = $false
    "DockerEngineRunning" = $false
    "UserPermissions" = $false
    "ContainersFeatureEnabled" = $false
    "ContainerFunctionality" = $false
}

# Check 1: Docker Desktop installation
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Checking Docker Desktop installation..."
if (Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe") {
    Write-Host "✅ Docker Desktop is installed"
    $healthStatus.DockerDesktopInstalled = $true
} else {
    Write-Host "❌ Docker Desktop is not installed"
}

# Check 2: Docker CLI availability
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Checking Docker CLI availability..."
$dockerCLI = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerCLI) {
    Write-Host "✅ Docker CLI is available at: $($dockerCLI.Source)"
    $healthStatus.DockerCLIAvailable = $true
} else {
    Write-Host "❌ Docker CLI is not available in PATH"
}

# Check 3: Docker service status
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Checking Docker service status..."
$dockerService = Get-Service -Name "docker" -ErrorAction SilentlyContinue
if ($dockerService -and $dockerService.Status -eq "Running") {
    Write-Host "✅ Docker service is running"
    $healthStatus.DockerServiceRunning = $true
} else {
    Write-Host "❌ Docker service is not running"
}

# Check 4: Docker engine connectivity
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Checking Docker engine connectivity..."
try {
    $dockerVersion = docker version --format json 2>$null | ConvertFrom-Json
    if ($dockerVersion.Server) {
        Write-Host "✅ Docker engine is running (Server version: $($dockerVersion.Server.Version))"
        $healthStatus.DockerEngineRunning = $true
    } else {
        Write-Host "❌ Docker engine is not responding"
    }
} catch {
    Write-Host "❌ Docker engine is not responding"
}

# Check 5: User permissions
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Checking user permissions..."
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$dockerUsers = Get-LocalGroupMember -Group "docker-users" -ErrorAction SilentlyContinue
$userInGroup = $dockerUsers | Where-Object { $_.Name -like "*$($env:USERNAME)" -or $_.Name -like "*deadline-worker*" -or $_.Name -like "*ssm-user*" }
if ($userInGroup) {
    Write-Host "✅ User has Docker permissions (docker-users group)"
    $healthStatus.UserPermissions = $true
} else {
    Write-Host "❌ User does not have Docker permissions"
}

# Check 6: Windows Containers feature
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Checking Windows Containers feature..."
$containersFeature = Get-WindowsOptionalFeature -Online -FeatureName Containers
if ($containersFeature.State -eq "Enabled") {
    Write-Host "✅ Windows Containers feature is enabled"
    $healthStatus.ContainersFeatureEnabled = $true
} else {
    Write-Host "❌ Windows Containers feature is not enabled"
}

# Check 7: Container functionality test
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Testing container functionality..."
if ($healthStatus.DockerEngineRunning) {
    try {
        Write-Host "  Pulling nanoserver image (if needed)..."
        docker pull mcr.microsoft.com/windows/nanoserver:ltsc2022 2>$null | Out-Null
        $testResult = docker run --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd /c "echo Docker test successful" 2>$null
        if ($testResult -like "*Docker test successful*") {
            Write-Host "✅ Container functionality test passed"
            $healthStatus.ContainerFunctionality = $true
        } else {
            Write-Host "❌ Container functionality test failed"
        }
    } catch {
        Write-Host "❌ Container functionality test failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "⚠️  Skipping container test - Docker engine not running"
}

# Summary
Write-Host ""
Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Health Check Summary:"
Write-Host "=================================="
$passedChecks = ($healthStatus.Values | Where-Object { $_ -eq $true }).Count
$totalChecks = $healthStatus.Count

foreach ($check in $healthStatus.GetEnumerator()) {
    $status = if ($check.Value) { "✅ PASS" } else { "❌ FAIL" }
    Write-Host "$($check.Key): $status"
}

Write-Host ""
Write-Host "Overall Status: $passedChecks/$totalChecks checks passed"

if ($passedChecks -eq $totalChecks) {
    Write-Host "🎉 Docker installation is healthy!"
} elseif ($passedChecks -ge 5) {
    Write-Host "⚠️  Docker installation has minor issues"
} else {
    Write-Host "❌ Docker installation has major issues"
}