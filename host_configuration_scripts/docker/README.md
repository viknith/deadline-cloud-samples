# Docker Desktop Installation for Windows

This directory contains scripts for installing Docker Desktop on Windows EC2 instances in headless mode.

## Scripts

### install-docker-desktop.ps1

Single-phase automated Docker Desktop installation script that:
- Enables Windows Containers feature
- Downloads Docker Desktop installer from S3
- Installs Docker Desktop with Windows containers backend
- Configures user permissions and PATH
- Initializes Docker Engine with automatic startup
- Reboots once to finalize setup

### docker-health-check.ps1

Health check script that verifies:
- Docker Desktop installation
- Docker CLI availability
- Docker service status
- Docker engine connectivity
- User permissions (docker-users group)
- Windows Containers feature
- Container functionality

## Usage

### Prerequisites

- Windows Server 2019/2022 or Windows 10/11
- Administrator privileges
- AWS CLI configured with S3 access permissions
- Docker Desktop installer available at: `s3://viknith-job-attachments/Installers/Docker Desktop Installer.exe`

### Installation

```powershell
# Run the installation script
.\install-docker-desktop.ps1
```

The script will:
1. Enable Windows Containers feature (no restart)
2. Download Docker Desktop installer from S3
3. Install Docker Desktop silently
4. Add users to docker-users group (deadline-worker, ssm-user)
5. Configure Docker CLI in system PATH
6. Register and start Docker service with automatic startup
7. Reboot to finalize Windows Containers feature

### Health Check

After installation and reboot, verify Docker is working:

```powershell
# Run health check
.\docker-health-check.ps1
```

The health check performs 7 tests and provides a summary of passed/failed checks.

### Manual Verification

```powershell
docker version
docker run --rm mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd /c "echo Docker test successful"
```

## Configuration

The script installs Docker Desktop with:
- **Backend**: Windows containers (native Windows container support)
- **Service mode**: Always running (`--always-run-service`)
- **User permissions**: Adds deadline-worker and ssm-user to docker-users group
- **License**: Automatically accepts Docker Desktop license
- **Startup**: Docker service configured for automatic startup after reboot

## Troubleshooting

### Common Issues

1. **S3 Access Denied (403)**
   - Ensure EC2 instance has IAM role with S3 read permissions
   - Verify AWS CLI is configured: `aws sts get-caller-identity`

2. **Docker Service Not Running After Reboot**
   - The script now configures automatic startup, but if issues persist:
   - Manually start: `Start-Service docker`
   - Check service: `Get-Service docker`

3. **Docker Commands Not Found**
   - Log out and back in to refresh PATH and group membership
   - Verify PATH includes: `C:\Program Files\Docker\Docker\resources\bin`

4. **Container Tests Fail**
   - Ensure Windows Containers feature is enabled: `Get-WindowsOptionalFeature -Online -FeatureName Containers`
   - Verify Docker is using Windows containers (not Linux containers)

### Cleanup

To remove Docker Desktop and reset for testing:

```powershell
# Uninstall Docker Desktop
$uninstaller = "C:\Program Files\Docker\Docker\Docker Desktop Installer.exe"
if (Test-Path $uninstaller) {
    Start-Process -FilePath $uninstaller -ArgumentList "uninstall --quiet" -Wait
}

# Disable Containers feature
Disable-WindowsOptionalFeature -Online -FeatureName Containers -NoRestart

# Reboot to complete cleanup
Restart-Computer -Force
```

## Notes

- Uses Windows containers backend (not WSL-2 or Hyper-V)
- Installation requires one reboot to finalize Windows Containers feature
- Total installation time is typically 8-15 minutes depending on instance size
- Docker service is configured for automatic startup after system reboots
- Script provides detailed timing measurements for performance monitoring