# Test Docker Container - After Effects Installation Verification and Render Test
# This script tests the Docker container to verify all software installations and runs a test render

$ErrorActionPreference = "Stop"

Write-Host "Testing After Effects Docker Container..."

# 1. Login to ECR
Write-Host "Logging into ECR..."
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 484745417699.dkr.ecr.us-west-2.amazonaws.com

# 2. Setup test directory
Write-Host "Setting up test directory..."
mkdir C:\temp\ae-test -Force
copy "C:\Users\viknith\Downloads\Frame_Counter(1).aep" "C:\temp\ae-test\Frame_Counter.aep"
mkdir C:\temp\ae-test\output -Force

# 3. Run Docker container with installation checks and AE render
Write-Host "Running Docker container with installation checks and render test..."
docker run --rm --memory=8g -v "C:\temp\ae-test:C:\workspace" 484745417699.dkr.ecr.us-west-2.amazonaws.com/ae-redgiant-full:latest powershell -Command "
Write-Host 'Checking installations...'

if (Test-Path 'C:\Program Files\Adobe\Adobe After Effects 2025\Support Files\aerender.exe') {
    Write-Host '✅ After Effects found'
} else {
    Write-Host '❌ After Effects not found'
}

if (Test-Path 'C:\Program Files\Red Giant\') {
    Write-Host '✅ Red Giant found'
} else {
    Write-Host '❌ Red Giant not found'
}

if (Test-Path 'C:\Program Files\Red Giant\Universe\') {
    Write-Host '✅ Universe found'
} else {
    Write-Host '❌ Universe not found'
}

if (Test-Path 'C:\Program Files\Maxon\') {
    Write-Host '✅ Maxon App found'
} else {
    Write-Host '❌ Maxon App not found'
}

Write-Host 'Environment variables:'
Write-Host 'AERENDER_EXECUTABLE:' `$env:AERENDER_EXECUTABLE
Write-Host 'MAXON_RENDERONLY:' `$env:MAXON_RENDERONLY

Write-Host 'Memory status:'
Get-WmiObject -Class Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory

Write-Host 'Starting render using render queue index 4...'
Write-Host 'Rendering to FrameCounter.mp4...'
& 'C:\Program Files\Adobe\Adobe After Effects 2025\Support Files\aerender.exe' -project 'C:\workspace\Frame_Counter.aep' -rqindex 4 -output 'C:\workspace\output\FrameCounter.mp4' -continueOnMissingFootage -close DO_NOT_SAVE_CHANGES -v ERRORS_AND_PROGRESS

Write-Host 'Render complete! Checking all workspace files:'
Get-ChildItem 'C:\workspace\' -Recurse
Write-Host 'Output folder contents:'
Get-ChildItem 'C:\workspace\output\' -ErrorAction SilentlyContinue
"

# 4. Check results on host
Write-Host "Checking results on host machine..."
Get-ChildItem C:\temp\ae-test\output\

Write-Host "Container test complete!"