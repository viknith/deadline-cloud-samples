# Host Configuration for Docker Desktop

This guide covers setting up Docker Desktop on Windows EC2 instances for containerized workloads in AWS Deadline Cloud. The installation script provides automated, headless Docker Desktop setup with proper user permissions and credential handling for ECR integration.

> **⚠️ Performance Impact**: This script adds about **5-8 minutes** to worker launch time due to Docker Desktop installation and Windows Containers feature setup. Plan accordingly for your fleet scaling and job scheduling.

## Prerequisites

- Windows Server 2019/2022 or Windows 10/11
- Administrator privileges  
- AWS CLI configured with appropriate permissions
- S3 bucket for storing Docker Desktop installer
- AWS Deadline Cloud farm with Windows fleet configured

## Required Installer

### Docker Desktop for Windows

Download from the [Docker Desktop for Windows installation page](https://docs.docker.com/desktop/setup/install/windows-install/):
1. Click **"Docker Desktop for Windows"** to download `Docker Desktop Installer.exe`

The installation script uses `--backend=windows` to configure Docker Desktop with Windows containers backend instead of WSL 2 or Hyper-V, providing native Windows container support for AWS EC2 instances.

## S3 Bucket Setup

### 1. Create S3 Bucket Structure

```bash
export INSTALLER_S3_BUCKET=your-installer-bucket
aws s3api put-object --bucket $INSTALLER_S3_BUCKET --key Installers/
```

### 2. Upload Docker Desktop Installer

```bash
export INSTALLER_S3_BUCKET=your-installer-bucket
aws s3 cp "Docker Desktop Installer.exe" s3://$INSTALLER_S3_BUCKET/Installers/
```

### 3. Update IAM Role Permissions

Add the following inline policy to your Fleet role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Sid": "ReadBucket",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::<your-bucket>/Installers/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceAccount": "<your-aws-account-id>"
                }
            }
        }
    ]
}
```

## Usage

### 1. Configure Installation Script

Update the S3 bucket name in the script:

```powershell
# Update this line in install-docker-desktop.ps1
aws s3 cp --no-progress "s3://your-installer-bucket/Installers/Docker Desktop Installer.exe" ".\Docker_Desktop_Installer.exe"
```

### 2. Deploy to Fleet

Add the contents of `install-docker-desktop.ps1` to your fleet's Configuration Scripts:

1. Navigate to **Fleets** in AWS Deadline Cloud console
2. Select your fleet
3. Go to **Configurations** tab
4. Add script under **Worker configuration script**

### 3. Test Installation Locally

```powershell
# Configure AWS credentials
aws configure

# Run the installation script
.\install-docker-desktop.ps1
```

The script will:
1. Enable Windows Containers feature
2. Download Docker Desktop installer from S3
3. Install Docker Desktop with Windows containers backend
4. Add users to docker-users and Administrators groups
5. Configure Docker CLI in system PATH
6. Disable UAC prompts for Administrator account
7. Set Administrator password for elevated operations
8. Reboot to finalize Windows Containers feature

## Troubleshooting

### Common Issues

1. **S3 Access Denied (403)**
   - Ensure EC2 instance has IAM role with S3 read permissions
   - Verify AWS CLI is configured: `aws sts get-caller-identity`

2. **Docker Processes Not Starting**
   - Check if all 5 required processes are running: `Docker Desktop`, `com.docker.build`, `com.docker.backend`, `com.docker.service`, `dockerd`

3. **ECR Login "Stub Received Bad Data" Error**
   - Job templates should delete `C:\Users\job-user\.docker` before Docker operations

4. **500 Internal Server Error on Docker Commands**
   - Switch Docker context: `docker context use default`

5. **Container Tests Fail**
   - Ensure Windows Containers feature is enabled: `Get-WindowsOptionalFeature -Online -FeatureName Containers`

## Integration with Job Templates

Job templates using Docker should include these steps:

1. **Remove Docker config directory** to avoid credential helper issues
2. **Wait for all 5 Docker processes** to ensure full startup
3. **Switch to default context** to avoid API connection problems
4. **Handle ECR authentication** with proper error handling

## Notes

- Uses Windows containers backend (not WSL-2 or Hyper-V)
- Installation requires one reboot to finalize Windows Containers feature
- Total installation time is typically 5-8 minutes depending on instance size
- Administrator password is set to enable job-level Docker operations
- UAC is disabled to prevent interactive prompts during job execution